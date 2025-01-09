// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {U512} from "./bn/U512.sol";
import {uint512} from "./bn/U512.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";
import "hardhat/console.sol";
/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 384-bit curve. Currently,
 * this is the most efficient implementation out there, consuming ~8.025 million gas per call.
 *
 * The approach is Strauss-Shamir double scalar multiplication with 6 bits of precompute + affine coordinates.
 * For reference, naive implementation uses ~400 billion gas, which is 50000 times more expensive.
 *
 * We also tried using projective coordinates, however, the gas consumption rose to ~9 million gas.
 */
library ECDSA384 {
    using MemoryUtils for *;
    using U512 for *;

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
        uint512 a;
        uint512 b;
        uint512 gx;
        uint512 gy;
        uint512 p;
        uint512 n;
        uint512 lowSmax;
    }

    struct _Inputs {
        uint512 r;
        uint512 s;
        uint512 x;
        uint512 y;
    }

    /**
     * @notice The function to verify the ECDSA signature
     * @param curveParams_ the 384-bit curve parameters. `lowSmax` is `n / 2`.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s > n / 2`, change it to `s = n - s`.
     */
    function verify(
        Parameters memory curveParams_,
        bytes memory hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            _Inputs memory inputs_;

            (inputs_.r, inputs_.s) = U512.init2(signature_);
            (inputs_.x, inputs_.y) = U512.init2(pubKey_);

            _Parameters memory params_ = _Parameters({
                a: curveParams_.a.init(),
                b: curveParams_.b.init(),
                gx: curveParams_.gx.init(),
                gy: curveParams_.gy.init(),
                p: curveParams_.p.init(),
                n: curveParams_.n.init(),
                lowSmax: curveParams_.lowSmax.init()
            });

            uint256 call = U512.initCall(params_.p);

            /// accept s only from the lower part of the curve
            if (
                U512.eqInteger(inputs_.r, 0) ||
                U512.cmp(inputs_.r, params_.n) >= 0 ||
                U512.eqInteger(inputs_.s, 0) ||
                U512.cmp(inputs_.s, params_.lowSmax) > 0
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

            uint512 scalar1 = U512.moddiv(call, hashedMessage_.init(), inputs_.s, params_.n);
            uint512 scalar2 = U512.moddiv(call, inputs_.r, inputs_.s, params_.n);

            {
                uint512 three = U512.init(3);

                /// We use 6-bit masks where the first 3 bits refer to `scalar1` and the last 3 bits refer to `scalar2`.
                uint512[2][64] memory points_ = _precomputePointsTable(
                    call,
                    params_.p,
                    three,
                    params_.a,
                    params_.gx,
                    params_.gy,
                    inputs_.x,
                    inputs_.y
                );

                (scalar1, ) = _doubleScalarMultiplication(
                    call,
                    params_.p,
                    three,
                    params_.a,
                    points_,
                    scalar1,
                    scalar2
                );
            }

            U512.modAssign(call, scalar1, params_.n);

            return U512.eq(scalar1, inputs_.r);
        }
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve.
     */
    function _isOnCurve(
        uint256 call,
        uint512 p,
        uint512 a,
        uint512 b,
        uint512 x,
        uint512 y
    ) private view returns (bool) {
        unchecked {
            if (U512.eqInteger(x, 0) || U512.eq(x, p) || U512.eqInteger(y, 0) || U512.eq(y, p)) {
                return false;
            }

            uint512 LHS = U512.modexp(call, y, 2);
            uint512 RHS = U512.modexp(call, x, 3);

            if (!U512.eqInteger(a, 0)) {
                RHS = U512.modadd(RHS, U512.modmul(call, x, a), p); // x^3 + a*x
            }

            if (!U512.eqInteger(b, 0)) {
                RHS = U512.modadd(RHS, b, p); // x^3 + a*x + b
            }

            return U512.eq(LHS, RHS);
        }
    }

    /**
     * @dev Compute the Strauss-Shamir double scalar multiplication scalar1*G + scalar2*H.
     */
    function _doubleScalarMultiplication(
        uint256 call,
        uint512 p,
        uint512 three,
        uint512 a,
        uint512[2][64] memory points,
        uint512 scalar1,
        uint512 scalar2
    ) private view returns (uint512 x, uint512 y) {
        unchecked {
            x = U512.init();
            y = U512.init();

            uint256 mask_;
            uint256 mask1_;
            uint256 mask2_;

            for (uint256 bit = 3; bit <= 384; bit += 3) {
                mask1_ = _getWord(scalar1, 384 - bit);
                mask2_ = _getWord(scalar2, 384 - bit);

                mask_ = (mask1_ << 3) | mask2_;

                if (mask_ != 0) {
                    (x, y) = _twice3Affine(call, p, three, a, x, y);
                    (x, y) = _addAffine(
                        call,
                        p,
                        three,
                        a,
                        points[mask_][0],
                        points[mask_][1],
                        x,
                        y
                    );
                }
            }
        }
    }

    function _getWord(uint512 scalar_, uint256 bit_) private pure returns (uint256) {
        unchecked {
            uint256 word_;
            if (bit_ <= 253) {
                assembly {
                    word_ := mload(add(scalar_, 0x20))
                }

                return (word_ >> bit_) & 0x07;
            }

            assembly {
                word_ := mload(add(scalar_, 0x10))
            }

            return (word_ >> (bit_ - 128)) & 0x07;
        }
    }

    /**
     * @dev Double an elliptic curve point in affine coordinates.
     */
    function _twiceAffine(
        uint256 call,
        uint512 p,
        uint512 three,
        uint512 a,
        uint512 x1,
        uint512 y1
    ) private view returns (uint512 x2, uint512 y2) {
        unchecked {
            x2 = U512.init();
            y2 = U512.init();

            if (x1.isNull()) {
                return (U512.init(), U512.init());
            }

            if (U512.eqInteger(y1, 0)) {
                return (U512.init(), U512.init());
            }

            uint512 m1 = U512.modexp(call, x1, 2);
            U512.modmulAssign(call, m1, three);
            U512.modaddAssign(m1, a, p);

            uint512 m2 = U512.modshl1(y1, p);
            U512.moddivAssign(call, m1, m2);

            x2 = U512.modexp(call, m1, 2);
            U512.modsubAssign(x2, x1, p);
            U512.modsubAssign(x2, x1, p);

            y2 = U512.modsub(x1, x2, p);
            U512.modmulAssign(call, y2, m1);
            U512.modsubAssign(y2, y1, p);
        }
    }

    /**
     * @dev Doubles an elliptic curve point 3 times in affine coordinates.
     */
    function _twice3Affine(
        uint256 call,
        uint512 p,
        uint512 three,
        uint512 a,
        uint512 x1,
        uint512 y1
    ) private view returns (uint512 x2, uint512 y2) {
        unchecked {
            x2 = U512.init();
            y2 = U512.init();

            if (x1.isNull()) {
                return (U512.init(), U512.init());
            }

            if (U512.eqInteger(y1, 0)) {
                return (U512.init(), U512.init());
            }

            uint512 m1 = U512.modexp(call, x1, 2);
            U512.modmulAssign(call, m1, three);
            U512.modaddAssign(m1, a, p);

            uint512 m2 = U512.modshl1(y1, p);
            U512.moddivAssign(call, m1, m2);

            x2 = U512.modexp(call, m1, 2);
            U512.modsubAssign(x2, x1, p);
            U512.modsubAssign(x2, x1, p);

            y2 = U512.modsub(x1, x2, p);
            U512.modmulAssign(call, y2, m1);
            U512.modsubAssign(y2, y1, p);

            if (U512.eqInteger(y2, 0)) {
                return (U512.init(), U512.init());
            }

            U512.modexpAssignTo(call, m1, x2, 2);
            U512.modmulAssign(call, m1, three);
            U512.modaddAssign(m1, a, p);

            U512.modshl1AssignTo(m2, y2, p);
            U512.moddivAssign(call, m1, m2);

            U512.modexpAssignTo(call, x1, m1, 2);
            U512.modsubAssign(x1, x2, p);
            U512.modsubAssign(x1, x2, p);

            U512.modsubAssignTo(y1, x2, x1, p);
            U512.modmulAssign(call, y1, m1);
            U512.modsubAssign(y1, y2, p);

            if (U512.eqInteger(y1, 0)) {
                return (U512.init(), U512.init());
            }

            U512.modexpAssignTo(call, m1, x1, 2);
            U512.modmulAssign(call, m1, three);
            U512.modaddAssign(m1, a, p);

            U512.modshl1AssignTo(m2, y1, p);
            U512.moddivAssign(call, m1, m2);

            U512.modexpAssignTo(call, x2, m1, 2);
            U512.modsubAssign(x2, x1, p);
            U512.modsubAssign(x2, x1, p);

            U512.modsubAssignTo(y2, x1, x2, p);
            U512.modmulAssign(call, y2, m1);
            U512.modsubAssign(y2, y1, p);
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates.
     */
    function _addAffine(
        uint256 call,
        uint512 p,
        uint512 three,
        uint512 a,
        uint512 x1,
        uint512 y1,
        uint512 x2,
        uint512 y2
    ) private view returns (uint512 x3, uint512 y3) {
        unchecked {
            x3 = U512.init();
            y3 = U512.init();

            if (x1.isNull() || x2.isNull()) {
                if (x1.isNull() && x2.isNull()) {
                    return (U512.init(), U512.init());
                }

                return x1.isNull() ? (x2.copy(), y2.copy()) : (x1.copy(), y1.copy());
            }

            if (U512.eq(x1, x2)) {
                if (U512.eq(y1, y2)) {
                    return _twiceAffine(call, p, three, a, x1, y1);
                }

                return (U512.init(), U512.init());
            }

            uint512 m1 = U512.modsub(y1, y2, p);
            uint512 m2 = U512.modsub(x1, x2, p);

            U512.moddivAssign(call, m1, m2);

            x3 = U512.modexp(call, m1, 2);
            U512.modsubAssign(x3, x1, p);
            U512.modsubAssign(x3, x2, p);

            y3 = U512.modsub(x1, x3, p);
            U512.modmulAssign(call, y3, m1);
            U512.modsubAssign(y3, y1, p);
        }
    }

    function _precomputePointsTable(
        uint256 call,
        uint512 p,
        uint512 three,
        uint512 a,
        uint512 gx,
        uint512 gy,
        uint512 hx,
        uint512 hy
    ) private view returns (uint512[2][64] memory points_) {
        unchecked {
            (points_[0x01][0], points_[0x01][1]) = (hx.copy(), hy.copy());
            (points_[0x08][0], points_[0x08][1]) = (gx.copy(), gy.copy());

            for (uint256 i = 0; i < 8; ++i) {
                for (uint256 j = 0; j < 8; ++j) {
                    if (i + j < 2) {
                        continue;
                    }

                    uint256 maskTo = (i << 3) | j;

                    if (i != 0) {
                        uint256 maskFrom = ((i - 1) << 3) | j;

                        (points_[maskTo][0], points_[maskTo][1]) = _addAffine(
                            call,
                            p,
                            three,
                            a,
                            points_[maskFrom][0],
                            points_[maskFrom][1],
                            gx,
                            gy
                        );
                    } else {
                        uint256 maskFrom = (i << 3) | (j - 1);

                        (points_[maskTo][0], points_[maskTo][1]) = _addAffine(
                            call,
                            p,
                            three,
                            a,
                            points_[maskFrom][0],
                            points_[maskFrom][1],
                            hx,
                            hy
                        );
                    }
                }
            }
        }
    }
}
