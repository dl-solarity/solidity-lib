// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../utils/MemoryUtils.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 384-bit curve. Currently,
 * this is the most efficient implementation out there, consuming ~9 million gas per call.
 *
 * The approach is Strauss-Shamir double scalar multiplication with 4 bits of precompute + projective points.
 */
library ECDSA384 {
    using MemoryUtils for *;
    using U384 for *;

    /**
     * @notice 384-bit curve parameters.
     */
    struct Parameters {
        bytes a;
        bytes b;
        bytes gx;
        bytes gy;
        bytes p;
        bytes n;
        bytes lowSmax;
    }

    struct _Parameters {
        uint256 a;
        uint256 b;
        uint256 gx;
        uint256 gy;
        uint256 p;
        uint256 n;
        uint256 lowSmax;
    }

    struct _Inputs {
        uint256 r;
        uint256 s;
        uint256 x;
        uint256 y;
    }

    /**
     * @notice The function to verify the ECDSA signature
     * @param curveParams_ the 384-bit curve parameters. `lowSmax` is `n / 2`.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s >= n / 2`, change it to `s = n - s`.
     */
    function verify(
        Parameters memory curveParams_,
        bytes memory hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            _Inputs memory inputs_;

            (inputs_.r, inputs_.s) = U384.init2(signature_);
            (inputs_.x, inputs_.y) = U384.init2(pubKey_);

            _Parameters memory params_ = _Parameters({
                a: curveParams_.a.init(),
                b: curveParams_.b.init(),
                gx: curveParams_.gx.init(),
                gy: curveParams_.gy.init(),
                p: curveParams_.p.init(),
                n: curveParams_.n.init(),
                lowSmax: curveParams_.lowSmax.init()
            });

            uint256 call = U384.initCall(params_.p);

            /// accept s only from the lower part of the curve
            if (
                U384.eqInteger(inputs_.r, 0) ||
                U384.cmp(inputs_.r, params_.n) >= 0 ||
                U384.eqInteger(inputs_.s, 0) ||
                U384.cmp(inputs_.s, params_.lowSmax) > 0
            ) {
                return false;
            }

            if (!_isOnCurve(call, params_.p, params_.a, params_.b, inputs_.x, inputs_.y)) {
                return false;
            }

            /// allow compatibility with non-384-bit hash functions.
            {
                uint256 hashedMessageLength_ = hashedMessage_.length;

                if (hashedMessageLength_ < 48) {
                    bytes memory tmp_ = new bytes(48);

                    MemoryUtils.unsafeCopy(
                        hashedMessage_.getDataPointer(),
                        tmp_.getDataPointer() + 48 - hashedMessageLength_,
                        hashedMessageLength_
                    );

                    hashedMessage_ = tmp_;
                }
            }

            uint256 scalar1 = U384.moddiv(call, hashedMessage_.init(), inputs_.s, params_.n);
            uint256 scalar2 = U384.moddiv(call, inputs_.r, inputs_.s, params_.n);

            {
                uint256 three = U384.init(3);

                /// We use 4-bit masks where the first 2 bits refer to `scalar1` and the last 2 bits refer to `scalar2`.
                uint256[3][16] memory points_ = _precomputePointsTable(
                    call,
                    params_.p,
                    three,
                    params_.a,
                    params_.gx,
                    params_.gy,
                    inputs_.x,
                    inputs_.y
                );

                (scalar1, , scalar2) = _doubleScalarMultiplication(
                    call,
                    params_.p,
                    three,
                    params_.a,
                    points_,
                    scalar1,
                    scalar2
                );
            }

            return U384.eq(U384.moddiv(call, scalar1, scalar2, params_.p), inputs_.r);
        }
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve.
     */
    function _isOnCurve(
        uint256 call,
        uint256 p,
        uint256 a,
        uint256 b,
        uint256 x,
        uint256 y
    ) private view returns (bool) {
        unchecked {
            if (U384.eqInteger(x, 0) || U384.eq(x, p) || U384.eqInteger(y, 0) || U384.eq(y, p)) {
                return false;
            }

            uint256 LHS = U384.modexp(call, y, 2);
            uint256 RHS = U384.modexp(call, x, 3);

            if (!U384.eqInteger(a, 0)) {
                RHS = U384.modadd(RHS, U384.modmul(call, x, a), p); // x^3 + a*x
            }

            if (!U384.eqInteger(b, 0)) {
                RHS = U384.modadd(RHS, b, p); // x^3 + a*x + b
            }

            return U384.eq(LHS, RHS);
        }
    }

    /**
     * @dev Compute the Strauss-Shamir double scalar multiplication scalar1*G + scalar2*H.
     */
    function _doubleScalarMultiplication(
        uint256 call,
        uint256 p,
        uint256 three,
        uint256 a,
        uint256[3][16] memory points,
        uint256 scalar1,
        uint256 scalar2
    ) private view returns (uint256 x, uint256 y, uint256 z) {
        unchecked {
            uint256 mask_;
            uint256 scalar1Bits_;
            uint256 scalar2Bits_;

            assembly {
                scalar1Bits_ := mload(scalar1)
                scalar2Bits_ := mload(scalar2)
            }

            x = U384.init(0);
            y = U384.init(0);
            z = U384.init(1);

            for (uint256 word = 2; word <= 184; word += 2) {
                (x, y, z) = _twiceProj(call, p, three, a, x, y, z);
                (x, y, z) = _twiceProj(call, p, three, a, x, y, z);

                mask_ =
                    (((scalar1Bits_ >> (184 - word)) & 0x03) << 2) |
                    ((scalar2Bits_ >> (184 - word)) & 0x03);

                if (mask_ != 0) {
                    uint256[3] memory maskedPoints_ = points[mask_];

                    (x, y, z) = _addProj(
                        call,
                        p,
                        three,
                        a,
                        maskedPoints_[0],
                        maskedPoints_[1],
                        maskedPoints_[2],
                        x,
                        y,
                        z
                    );
                }
            }

            assembly {
                scalar1Bits_ := mload(add(scalar1, 0x20))
                scalar2Bits_ := mload(add(scalar2, 0x20))
            }

            for (uint256 word = 2; word <= 256; word += 2) {
                (x, y, z) = _twiceProj(call, p, three, a, x, y, z);
                (x, y, z) = _twiceProj(call, p, three, a, x, y, z);

                mask_ =
                    (((scalar1Bits_ >> (256 - word)) & 0x03) << 2) |
                    ((scalar2Bits_ >> (256 - word)) & 0x03);

                if (mask_ != 0) {
                    uint256[3] memory maskedPoints_ = points[mask_];

                    (x, y, z) = _addProj(
                        call,
                        p,
                        three,
                        a,
                        maskedPoints_[0],
                        maskedPoints_[1],
                        maskedPoints_[2],
                        x,
                        y,
                        z
                    );
                }
            }

            return (x, y, z);
        }
    }

    /**
     * @dev Double an elliptic curve point in projective coordinates. See
     * https://www.nayuki.io/page/elliptic-curve-point-addition-in-projective-coordinates
     */
    function _twiceProj(
        uint256 call,
        uint256 p,
        uint256 three,
        uint256 a,
        uint256 x0,
        uint256 y0,
        uint256 z0
    ) private view returns (uint256 x1, uint256 y1, uint256 z1) {
        unchecked {
            if (U384.eqInteger(x0, 0) && U384.eqInteger(y0, 0)) {
                return (U384.init(0), U384.init(0), U384.init(1)); // zero proj
            }

            uint256 u = U384.modmul(call, y0, z0);
            U384.modshl1Assign(u, p);

            x1 = U384.modmul(call, u, x0);
            U384.modmulAssign(call, x1, y0);
            U384.modshl1Assign(x1, p);

            x0 = U384.modexp(call, x0, 2);

            y1 = U384.modmul(call, x0, three);

            z0 = U384.modexp(call, z0, 2);
            U384.modmulAssign(call, z0, a);
            U384.modaddAssign(y1, z0, p);

            z1 = U384.modexp(call, y1, 2);
            U384.modshl1AssignTo(x0, x1, p);

            uint256 diff = U384.sub(p, x0);
            U384.modaddAssign(z1, diff, p);

            U384.subAssignTo(diff, p, z1);
            U384.modaddAssignTo(x0, x1, diff, p);
            U384.modmulAssign(call, x0, y1);

            y0 = U384.modmul(call, y0, u);
            U384.modexpAssign(call, y0, 2);
            U384.modshl1Assign(y0, p);

            U384.subAssignTo(diff, p, y0);
            U384.modaddAssignTo(y1, x0, diff, p);

            U384.modmulAssignTo(call, x1, u, z1);

            U384.modexpAssignTo(call, z1, u, 2);
            U384.modmulAssign(call, z1, u);
        }
    }

    /**
     * @dev Add two elliptic curve points in projective coordinates. See
     * https://www.nayuki.io/page/elliptic-curve-point-addition-in-projective-coordinates
     */
    function _addProj(
        uint256 call,
        uint256 p,
        uint256 three,
        uint256 a,
        uint256 x0,
        uint256 y0,
        uint256 z0,
        uint256 x1,
        uint256 y1,
        uint256 z1
    ) private view returns (uint256 x2, uint256 y2, uint256 z2) {
        unchecked {
            if (U384.eqInteger(x0, 0) && U384.eqInteger(y0, 0)) {
                return (x1.copy(), y1.copy(), z1.copy());
            } else if (U384.eqInteger(x1, 0) && U384.eqInteger(y1, 0)) {
                return (x0.copy(), y0.copy(), z0.copy());
            }

            x2 = U384.modmul(call, y0, z1);
            y2 = U384.modmul(call, y1, z0);
            z2 = U384.modmul(call, x0, z1);
            y1 = U384.modmul(call, x1, z0);

            if (U384.eq(z2, y1)) {
                if (U384.eq(x2, y2)) {
                    return _twiceProj(call, p, three, a, x0, y0, z0);
                } else {
                    return (U384.init(0), U384.init(0), U384.init(1)); // zero proj
                }
            }

            a = U384.modmul(call, z0, z1);

            return _addProj2(call, a, z2, p, y1, y2, x2);
        }
    }

    /**
     * @dev Helper function that splits addProj to avoid too many local variables.
     */
    function _addProj2(
        uint256 call,
        uint256 v,
        uint256 u0,
        uint256 p,
        uint256 u1,
        uint256 t1,
        uint256 t0
    ) private view returns (uint256 x2, uint256 y2, uint256 z2) {
        unchecked {
            uint256 diff = U384.sub(p, t1);
            y2 = U384.modadd(t0, diff, p);

            U384.subAssignTo(diff, p, u1);
            x2 = U384.modadd(u0, diff, p);
            uint256 u2 = U384.modexp(call, x2, 2);

            z2 = U384.modexp(call, y2, 2);

            U384.modmulAssign(call, z2, v);
            u1 = U384.modadd(u1, u0, p);
            U384.modmulAssign(call, u1, u2);
            U384.subAssignTo(diff, p, u1);
            U384.modaddAssign(z2, diff, p);

            uint256 u3 = U384.modmul(call, u2, x2);

            U384.modmulAssign(call, x2, z2);

            u0 = U384.modmul(call, u0, u2);

            U384.subAssignTo(diff, p, z2);
            U384.modaddAssign(u0, diff, p);
            U384.modmulAssign(call, y2, u0);
            t0 = U384.modmul(call, t0, u3);

            U384.subAssignTo(diff, p, t0);
            U384.modaddAssign(y2, diff, p);

            U384.modmulAssignTo(call, z2, u3, v);
        }
    }

    function _precomputePointsTable(
        uint256 call,
        uint256 p,
        uint256 three,
        uint256 a,
        uint256 gx,
        uint256 gy,
        uint256 hx,
        uint256 hy
    ) private view returns (uint256[3][16] memory points_) {
        /// 0b0100: 1G + 0H
        (points_[0x04][0], points_[0x04][1], points_[0x04][2]) = (
            gx.copy(),
            gy.copy(),
            U384.init(1)
        );
        /// 0b1000: 2G + 0H
        (points_[0x08][0], points_[0x08][1], points_[0x08][2]) = _twiceProj(
            call,
            p,
            three,
            a,
            points_[0x04][0],
            points_[0x04][1],
            points_[0x04][2]
        );
        /// 0b1100: 3G + 0H
        (points_[0x0C][0], points_[0x0C][1], points_[0x0C][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x04][0],
            points_[0x04][1],
            points_[0x04][2],
            points_[0x08][0],
            points_[0x08][1],
            points_[0x08][2]
        );
        /// 0b0001: 0G + 1H
        (points_[0x01][0], points_[0x01][1], points_[0x01][2]) = (
            hx.copy(),
            hy.copy(),
            U384.init(1)
        );
        /// 0b0010: 0G + 2H
        (points_[0x02][0], points_[0x02][1], points_[0x02][2]) = _twiceProj(
            call,
            p,
            three,
            a,
            points_[0x01][0],
            points_[0x01][1],
            points_[0x01][2]
        );
        /// 0b0011: 0G + 3H
        (points_[0x03][0], points_[0x03][1], points_[0x03][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x01][0],
            points_[0x01][1],
            points_[0x01][2],
            points_[0x02][0],
            points_[0x02][1],
            points_[0x02][2]
        );
        /// 0b0101: 1G + 1H
        (points_[0x05][0], points_[0x05][1], points_[0x05][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x04][0],
            points_[0x04][1],
            points_[0x04][2],
            points_[0x01][0],
            points_[0x01][1],
            points_[0x01][2]
        );
        /// 0b0110: 1G + 2H
        (points_[0x06][0], points_[0x06][1], points_[0x06][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x04][0],
            points_[0x04][1],
            points_[0x04][2],
            points_[0x02][0],
            points_[0x02][1],
            points_[0x02][2]
        );
        /// 0b0111: 1G + 3H
        (points_[0x07][0], points_[0x07][1], points_[0x07][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x04][0],
            points_[0x04][1],
            points_[0x04][2],
            points_[0x03][0],
            points_[0x03][1],
            points_[0x03][2]
        );
        /// 0b1001: 2G + 1H
        (points_[0x09][0], points_[0x09][1], points_[0x09][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x08][0],
            points_[0x08][1],
            points_[0x08][2],
            points_[0x01][0],
            points_[0x01][1],
            points_[0x01][2]
        );
        /// 0b1010: 2G + 2H
        (points_[0x0A][0], points_[0x0A][1], points_[0x0A][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x08][0],
            points_[0x08][1],
            points_[0x08][2],
            points_[0x02][0],
            points_[0x02][1],
            points_[0x02][2]
        );
        /// 0b1011: 2G + 3H
        (points_[0x0B][0], points_[0x0B][1], points_[0x0B][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x08][0],
            points_[0x08][1],
            points_[0x08][2],
            points_[0x03][0],
            points_[0x03][1],
            points_[0x03][2]
        );
        /// 0b1101: 3G + 1H
        (points_[0x0D][0], points_[0x0D][1], points_[0x0D][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x0C][0],
            points_[0x0C][1],
            points_[0x0C][2],
            points_[0x01][0],
            points_[0x01][1],
            points_[0x01][2]
        );
        /// 0b1110: 3G + 2H
        (points_[0x0E][0], points_[0x0E][1], points_[0x0E][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x0C][0],
            points_[0x0C][1],
            points_[0x0C][2],
            points_[0x02][0],
            points_[0x02][1],
            points_[0x02][2]
        );
        /// 0b1111: 3G + 3H
        (points_[0x0F][0], points_[0x0F][1], points_[0x0F][2]) = _addProj(
            call,
            p,
            three,
            a,
            points_[0x0C][0],
            points_[0x0C][1],
            points_[0x0C][2],
            points_[0x03][0],
            points_[0x03][1],
            points_[0x03][2]
        );
    }
}

/**
 * @notice Low-level utility library that implements unsigned 384-bit arithmetics.
 *
 * Should not be used outside of this file.
 */
library U384 {
    uint256 private constant SHORT_ALLOCATION = 64;
    uint256 private constant LONG_ALLOCATION = 96;

    uint256 private constant CALL_ALLOCATION = 3 * 288;

    uint256 private constant MUL_OFFSET = 288;
    uint256 private constant EXP_OFFSET = 2 * 288;

    function init(uint256 from_) internal pure returns (uint256 handler_) {
        unchecked {
            handler_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler_, 0x00)
                mstore(add(0x20, handler_), from_)
            }

            return handler_;
        }
    }

    function init(bytes memory from_) internal pure returns (uint256 handler_) {
        unchecked {
            require(from_.length == 48, "U384: not 384");

            handler_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler_, 0x00)
                mstore(add(handler_, 0x10), mload(add(from_, 0x20)))
                mstore(add(handler_, 0x20), mload(add(from_, 0x30)))
            }

            return handler_;
        }
    }

    function init2(
        bytes memory from2_
    ) internal pure returns (uint256 handler1_, uint256 handler2_) {
        unchecked {
            require(from2_.length == 96, "U384: not 768");

            handler1_ = _allocate(SHORT_ALLOCATION);
            handler2_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler1_, 0x00)
                mstore(add(handler1_, 0x10), mload(add(from2_, 0x20)))
                mstore(add(handler1_, 0x20), mload(add(from2_, 0x30)))

                mstore(handler2_, 0x00)
                mstore(add(handler2_, 0x10), mload(add(from2_, 0x50)))
                mstore(add(handler2_, 0x20), mload(add(from2_, 0x60)))
            }

            return (handler1_, handler2_);
        }
    }

    function initCall(uint256 m_) internal pure returns (uint256 handler_) {
        unchecked {
            handler_ = _allocate(CALL_ALLOCATION);

            assembly {
                let call_ := add(handler_, MUL_OFFSET)

                mstore(call_, 0x60)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), 0x01)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                call_ := add(handler_, EXP_OFFSET)

                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), mload(m_))
                mstore(add(0xE0, call_), mload(add(m_, 0x20)))
            }
        }
    }

    function copy(uint256 handler_) internal pure returns (uint256 handlerCopy_) {
        unchecked {
            handlerCopy_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handlerCopy_, mload(handler_))
                mstore(add(handlerCopy_, 0x20), mload(add(handler_, 0x20)))
            }

            return handlerCopy_;
        }
    }

    function eq(uint256 a_, uint256 b_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), mload(b_)), eq(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
        }
    }

    function eqInteger(uint256 a_, uint256 bInteger_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), 0), eq(mload(add(a_, 0x20)), bInteger_))
        }
    }

    function cmp(uint256 a_, uint256 b_) internal pure returns (int256 cmp_) {
        unchecked {
            uint256 aWord_;
            uint256 bWord_;

            assembly {
                aWord_ := mload(a_)
                bWord_ := mload(b_)
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }

            assembly {
                aWord_ := mload(add(a_, 0x20))
                bWord_ := mload(add(b_, 0x20))
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }
        }
    }

    function modexp(
        uint256 call_,
        uint256 b_,
        uint256 eInteger_
    ) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            assembly {
                call_ := add(call_, EXP_OFFSET)

                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))
                mstore(add(0xA0, call_), eInteger_)

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            return r_;
        }
    }

    function modexpAssign(uint256 call_, uint256 b_, uint256 eInteger_) internal view {
        assembly {
            call_ := add(call_, EXP_OFFSET)

            mstore(add(0x60, call_), mload(b_))
            mstore(add(0x80, call_), mload(add(b_, 0x20)))
            mstore(add(0xA0, call_), eInteger_)

            pop(staticcall(gas(), 0x5, call_, 0x0100, b_, 0x40))
        }
    }

    function modexpAssignTo(
        uint256 call_,
        uint256 to_,
        uint256 b_,
        uint256 eInteger_
    ) internal view {
        assembly {
            call_ := add(call_, EXP_OFFSET)

            mstore(add(0x60, call_), mload(b_))
            mstore(add(0x80, call_), mload(add(b_, 0x20)))
            mstore(add(0xA0, call_), eInteger_)

            pop(staticcall(gas(), 0x5, call_, 0x0100, to_, 0x40))
        }
    }

    function modadd(uint256 a_, uint256 b_, uint256 m_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _add(a_, b_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modaddAssign(uint256 a_, uint256 b_, uint256 m_) internal pure {
        unchecked {
            _addTo(a_, b_);

            if (cmp(a_, m_) >= 0) {
                return _subFrom(a_, m_);
            }
        }
    }

    function modaddAssignTo(uint256 to_, uint256 a_, uint256 b_, uint256 m_) internal pure {
        unchecked {
            _add(a_, b_, to_);

            if (cmp(to_, m_) >= 0) {
                return _subFrom(to_, m_);
            }
        }
    }

    function modmul(uint256 call_, uint256 a_, uint256 b_) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _mul(a_, b_, call_ + MUL_OFFSET + 0x60);

            assembly {
                call_ := add(call_, MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }

            return r_;
        }
    }

    function modmulAssign(uint256 call_, uint256 a_, uint256 b_) internal view {
        unchecked {
            _mul(a_, b_, call_ + MUL_OFFSET + 0x60);

            assembly {
                call_ := add(call_, MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, a_, 0x40))
            }
        }
    }

    function modmulAssignTo(uint256 call_, uint256 to_, uint256 a_, uint256 b_) internal view {
        unchecked {
            _mul(a_, b_, call_ + MUL_OFFSET + 0x60);

            assembly {
                call_ := add(call_, MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, to_, 0x40))
            }
        }
    }

    function sub(uint256 a_, uint256 b_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _sub(a_, b_, r_);

            return r_;
        }
    }

    function subAssignTo(uint256 to_, uint256 a_, uint256 b_) internal pure {
        unchecked {
            _sub(a_, b_, to_);
        }
    }

    function modshl1(uint256 a_, uint256 m_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _shl1(a_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modshl1Assign(uint256 a_, uint256 m_) internal pure {
        unchecked {
            _shl1To(a_);

            if (cmp(a_, m_) >= 0) {
                _subFrom(a_, m_);
            }
        }
    }

    function modshl1AssignTo(uint256 to_, uint256 a_, uint256 m_) internal pure {
        unchecked {
            _shl1(a_, to_);

            if (cmp(to_, m_) >= 0) {
                _subFrom(to_, m_);
            }
        }
    }

    function moddiv(
        uint256 call_,
        uint256 a_,
        uint256 b_,
        uint256 m_
    ) internal view returns (uint256 r_) {
        unchecked {
            r_ = modinv(call_, b_, m_);

            _mul(a_, r_, call_ + 0x60);

            assembly {
                mstore(call_, 0x60)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), 0x01)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function modinv(uint256 call_, uint256 b_, uint256 m_) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _sub(m_, init(2), call_ + 0xA0);

            assembly {
                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function mod(uint256 call_, uint256 a_, uint256 m_) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0x60, call_), mload(a_))
                mstore(add(0x80, call_), mload(add(a_, 0x20)))
                mstore(add(0xA0, call_), 0x01)
                mstore(add(0xC0, call_), mload(m_))
                mstore(add(0xE0, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            return r_;
        }
    }

    function toBytes(uint256 handler_) internal pure returns (bytes memory bytes_) {
        unchecked {
            uint256 bytesHandler_ = _allocate(LONG_ALLOCATION);

            assembly {
                bytes_ := bytesHandler_

                mstore(bytes_, 0x40)
                mstore(add(0x20, bytes_), mload(handler_))
                mstore(add(0x40, bytes_), mload(add(handler_, 0x20)))
            }

            return bytes_;
        }
    }

    function _shl1(uint256 a_, uint256 r_) internal pure {
        assembly {
            let a1_ := mload(add(a_, 0x20))

            mstore(r_, or(shl(1, mload(a_)), shr(255, a1_)))
            mstore(add(r_, 0x20), shl(1, a1_))
        }
    }

    function _shl1To(uint256 a_) internal pure {
        assembly {
            let a1_ := mload(add(a_, 0x20))

            mstore(a_, or(shl(1, mload(a_)), shr(255, a1_)))
            mstore(add(a_, 0x20), shl(1, a1_))
        }
    }

    function _add(uint256 a_, uint256 b_, uint256 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(r_, sum_)
        }
    }

    function _sub(uint256 a_, uint256 b_, uint256 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(r_, diff_)
        }
    }

    function _subFrom(uint256 a_, uint256 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(a_, diff_)
        }
    }

    function _addTo(uint256 a_, uint256 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(a_, sum_)
        }
    }

    function _mul(uint256 a_, uint256 b_, uint256 r_) private view {
        assembly {
            let a0_ := mload(a_)
            let a1_ := shr(128, mload(add(a_, 0x20)))
            let a2_ := and(mload(add(a_, 0x20)), 0xffffffffffffffffffffffffffffffff)

            let b0_ := mload(b_)
            let b1_ := shr(128, mload(add(b_, 0x20)))
            let b2_ := and(mload(add(b_, 0x20)), 0xffffffffffffffffffffffffffffffff)

            // r5
            let current_ := mul(a2_, b2_)
            let r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

            // r4
            current_ := shr(128, current_)

            let temp_ := mul(a1_, b2_)
            current_ := add(current_, temp_)
            let curry_ := lt(current_, temp_)

            temp_ := mul(a2_, b1_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            mstore(add(r_, 0x40), add(shl(128, current_), r0_))

            // r3
            current_ := add(shl(128, curry_), shr(128, current_))
            curry_ := callvalue() // same as := 0 but less expensive

            temp_ := mul(a0_, b2_)
            current_ := add(current_, temp_)
            curry_ := lt(current_, temp_)

            temp_ := mul(a1_, b1_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            temp_ := mul(a2_, b0_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

            // r2
            current_ := add(shl(128, curry_), shr(128, current_))
            curry_ := callvalue()

            temp_ := mul(a0_, b1_)
            current_ := add(current_, temp_)
            curry_ := lt(current_, temp_)

            temp_ := mul(a1_, b0_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            mstore(add(r_, 0x20), add(shl(128, current_), r0_))

            // r1
            current_ := add(shl(128, curry_), shr(128, current_))
            current_ := add(current_, mul(a0_, b0_))

            mstore(r_, current_)
        }
    }

    function _allocate(uint256 bytes_) private pure returns (uint256 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }

            return handler_;
        }
    }
}
