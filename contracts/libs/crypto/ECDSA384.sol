// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../utils/MemoryUtils.sol";
import {_U384} from "./backend/U384.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 384-bit curve. Currently,
 * this is the most efficient implementation out there, consuming ~7.767 million gas per call.
 *
 * The approach is Strauss-Shamir double scalar multiplication with 6 bits of precompute + affine coordinates.
 * For reference, naive implementation uses ~400 billion gas, which is ~50000 times more expensive.
 *
 * We also tried using projective coordinates, however, the gas consumption rose to ~9 million gas.
 */
library ECDSA384 {
    using MemoryUtils for *;

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

            (inputs_.r, inputs_.s) = _u384FromBytes2(signature_);
            (inputs_.x, inputs_.y) = _u384FromBytes2(pubKey_);

            _Parameters memory params_ = _Parameters({
                a: _U384.fromBytes(curveParams_.a),
                b: _U384.fromBytes(curveParams_.b),
                gx: _U384.fromBytes(curveParams_.gx),
                gy: _U384.fromBytes(curveParams_.gy),
                p: _U384.fromBytes(curveParams_.p),
                n: _U384.fromBytes(curveParams_.n),
                lowSmax: _U384.fromBytes(curveParams_.lowSmax)
            });

            uint256 call_ = _U384.initCall(params_.p);

            /// accept s only from the lower part of the curve
            if (
                _U384.eqUint256(inputs_.r, 0) ||
                _U384.cmp(inputs_.r, params_.n) >= 0 ||
                _U384.eqUint256(inputs_.s, 0) ||
                _U384.cmp(inputs_.s, params_.lowSmax) > 0
            ) {
                return false;
            }

            if (!_isOnCurve(call_, params_.p, params_.a, params_.b, inputs_.x, inputs_.y)) {
                return false;
            }

            uint256 scalar1_ = _U384.moddiv(
                call_,
                _U384.fromBytes(hashedMessage_),
                inputs_.s,
                params_.n
            );
            uint256 scalar2_ = _U384.moddiv(call_, inputs_.r, inputs_.s, params_.n);

            {
                uint256 three_ = _U384.fromUint256(3);

                /// We use 6-bit masks where the first 3 bits refer to `scalar1` and the last 3 bits refer to `scalar2`.
                uint256[2][64] memory points_ = _precomputePointsTable(
                    call_,
                    params_.p,
                    three_,
                    params_.a,
                    inputs_.x,
                    inputs_.y,
                    params_.gx,
                    params_.gy
                );

                (scalar1_, ) = _doubleScalarMultiplication(
                    call_,
                    params_.p,
                    three_,
                    params_.a,
                    points_,
                    scalar1_,
                    scalar2_
                );
            }

            _U384.modAssign(call_, scalar1_, params_.n);

            return _U384.eq(scalar1_, inputs_.r);
        }
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve.
     */
    function _isOnCurve(
        uint256 call_,
        uint256 p_,
        uint256 a_,
        uint256 b_,
        uint256 x_,
        uint256 y_
    ) private view returns (bool) {
        unchecked {
            if (
                _U384.eqUint256(x_, 0) ||
                _U384.eq(x_, p_) ||
                _U384.eqUint256(y_, 0) ||
                _U384.eq(y_, p_)
            ) {
                return false;
            }

            uint256 lhs_ = _U384.modexp(call_, y_, 2);
            uint256 rhs_ = _U384.modexp(call_, x_, 3);

            if (!_U384.eqUint256(a_, 0)) {
                rhs_ = _U384.modadd(rhs_, _U384.modmul(call_, x_, a_), p_); // x^3 + a*x
            }

            if (!_U384.eqUint256(b_, 0)) {
                rhs_ = _U384.modadd(rhs_, b_, p_); // x^3 + a*x + b
            }

            return _U384.eq(lhs_, rhs_);
        }
    }

    /**
     * @dev Compute the Strauss-Shamir double scalar multiplication scalar1*G + scalar2*H.
     */
    function _doubleScalarMultiplication(
        uint256 call_,
        uint256 p_,
        uint256 three_,
        uint256 a_,
        uint256[2][64] memory points_,
        uint256 scalar1_,
        uint256 scalar2_
    ) private view returns (uint256 x_, uint256 y_) {
        unchecked {
            uint256 mask_;
            uint256 mask1_;
            uint256 mask2_;

            for (uint256 bit = 3; bit <= 384; bit += 3) {
                mask1_ = _getWord(scalar1_, 384 - bit);
                mask2_ = _getWord(scalar2_, 384 - bit);

                mask_ = (mask1_ << 3) | mask2_;

                if (mask_ != 0) {
                    (x_, y_) = _twice3Affine(call_, p_, three_, a_, x_, y_);
                    (x_, y_) = _addAffine(
                        call_,
                        p_,
                        three_,
                        a_,
                        points_[mask_][0],
                        points_[mask_][1],
                        x_,
                        y_
                    );
                }
            }

            return (x_, y_);
        }
    }

    function _getWord(uint256 scalar_, uint256 bit_) private pure returns (uint256) {
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
        uint256 call_,
        uint256 p_,
        uint256 three_,
        uint256 a_,
        uint256 x1_,
        uint256 y1_
    ) private view returns (uint256 x2_, uint256 y2_) {
        unchecked {
            if (x1_ == 0) {
                return (0, 0);
            }

            if (_U384.eqUint256(y1_, 0)) {
                return (0, 0);
            }

            uint256 m1_ = _U384.modexp(call_, x1_, 2);
            _U384.modmulAssign(call_, m1_, three_);
            _U384.modaddAssign(m1_, a_, p_);

            uint256 m2_ = _U384.modshl1(y1_, p_);
            _U384.moddivAssign(call_, m1_, m2_);

            x2_ = _U384.modexp(call_, m1_, 2);
            _U384.modsubAssign(x2_, x1_, p_);
            _U384.modsubAssign(x2_, x1_, p_);

            y2_ = _U384.modsub(x1_, x2_, p_);
            _U384.modmulAssign(call_, y2_, m1_);
            _U384.modsubAssign(y2_, y1_, p_);
        }
    }

    /**
     * @dev Doubles an elliptic curve point 3 times in affine coordinates.
     */
    function _twice3Affine(
        uint256 call_,
        uint256 p_,
        uint256 three_,
        uint256 a_,
        uint256 x1_,
        uint256 y1_
    ) private view returns (uint256 x2_, uint256 y2_) {
        unchecked {
            if (x1_ == 0) {
                return (0, 0);
            }

            if (_U384.eqUint256(y1_, 0)) {
                return (0, 0);
            }

            uint256 m1 = _U384.modexp(call_, x1_, 2);
            _U384.modmulAssign(call_, m1, three_);
            _U384.modaddAssign(m1, a_, p_);

            uint256 m2 = _U384.modshl1(y1_, p_);
            _U384.moddivAssign(call_, m1, m2);

            x2_ = _U384.modexp(call_, m1, 2);
            _U384.modsubAssign(x2_, x1_, p_);
            _U384.modsubAssign(x2_, x1_, p_);

            y2_ = _U384.modsub(x1_, x2_, p_);
            _U384.modmulAssign(call_, y2_, m1);
            _U384.modsubAssign(y2_, y1_, p_);

            if (_U384.eqUint256(y2_, 0)) {
                return (0, 0);
            }

            _U384.modexpAssignTo(call_, m1, x2_, 2);
            _U384.modmulAssign(call_, m1, three_);
            _U384.modaddAssign(m1, a_, p_);

            _U384.modshl1AssignTo(m2, y2_, p_);
            _U384.moddivAssign(call_, m1, m2);

            _U384.modexpAssignTo(call_, x1_, m1, 2);
            _U384.modsubAssign(x1_, x2_, p_);
            _U384.modsubAssign(x1_, x2_, p_);

            _U384.modsubAssignTo(y1_, x2_, x1_, p_);
            _U384.modmulAssign(call_, y1_, m1);
            _U384.modsubAssign(y1_, y2_, p_);

            if (_U384.eqUint256(y1_, 0)) {
                return (0, 0);
            }

            _U384.modexpAssignTo(call_, m1, x1_, 2);
            _U384.modmulAssign(call_, m1, three_);
            _U384.modaddAssign(m1, a_, p_);

            _U384.modshl1AssignTo(m2, y1_, p_);
            _U384.moddivAssign(call_, m1, m2);

            _U384.modexpAssignTo(call_, x2_, m1, 2);
            _U384.modsubAssign(x2_, x1_, p_);
            _U384.modsubAssign(x2_, x1_, p_);

            _U384.modsubAssignTo(y2_, x1_, x2_, p_);
            _U384.modmulAssign(call_, y2_, m1);
            _U384.modsubAssign(y2_, y1_, p_);
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates.
     */
    function _addAffine(
        uint256 call_,
        uint256 p_,
        uint256 three_,
        uint256 a_,
        uint256 x1_,
        uint256 y1_,
        uint256 x2_,
        uint256 y2_
    ) private view returns (uint256 x3, uint256 y3) {
        unchecked {
            if (x1_ == 0 || x2_ == 0) {
                if (x1_ == 0 && x2_ == 0) {
                    return (0, 0);
                }

                return
                    x1_ == 0
                        ? (_U384.copy(x2_), _U384.copy(y2_))
                        : (_U384.copy(x1_), _U384.copy(y1_));
            }

            if (_U384.eq(x1_, x2_)) {
                if (_U384.eq(y1_, y2_)) {
                    return _twiceAffine(call_, p_, three_, a_, x1_, y1_);
                }

                return (0, 0);
            }

            uint256 m1_ = _U384.modsub(y1_, y2_, p_);
            uint256 m2_ = _U384.modsub(x1_, x2_, p_);

            _U384.moddivAssign(call_, m1_, m2_);

            x3 = _U384.modexp(call_, m1_, 2);
            _U384.modsubAssign(x3, x1_, p_);
            _U384.modsubAssign(x3, x2_, p_);

            y3 = _U384.modsub(x1_, x3, p_);
            _U384.modmulAssign(call_, y3, m1_);
            _U384.modsubAssign(y3, y1_, p_);
        }
    }

    function _precomputePointsTable(
        uint256 call_,
        uint256 p_,
        uint256 three_,
        uint256 a_,
        uint256 hx_,
        uint256 hy_,
        uint256 gx_,
        uint256 gy_
    ) private view returns (uint256[2][64] memory points_) {
        unchecked {
            (points_[0x01][0], points_[0x01][1]) = (_U384.copy(hx_), _U384.copy(hy_));
            (points_[0x08][0], points_[0x08][1]) = (_U384.copy(gx_), _U384.copy(gy_));

            for (uint256 i = 0; i < 8; ++i) {
                for (uint256 j = 0; j < 8; ++j) {
                    if (i + j < 2) {
                        continue;
                    }

                    uint256[2] memory pointTo_ = points_[(i << 3) | j];

                    if (i != 0) {
                        uint256[2] memory pointFrom_ = points_[((i - 1) << 3) | j];

                        (pointTo_[0], pointTo_[1]) = _addAffine(
                            call_,
                            p_,
                            three_,
                            a_,
                            pointFrom_[0],
                            pointFrom_[1],
                            gx_,
                            gy_
                        );
                    } else {
                        uint256[2] memory pointFrom_ = points_[(i << 3) | (j - 1)];

                        (pointTo_[0], pointTo_[1]) = _addAffine(
                            call_,
                            p_,
                            three_,
                            a_,
                            pointFrom_[0],
                            pointFrom_[1],
                            hx_,
                            hy_
                        );
                    }
                }
            }

            return points_;
        }
    }

    /**
     * @dev Convert 96 bytes to two 384-bit unsigned integers.
     */
    function _u384FromBytes2(bytes memory bytes_) private view returns (uint256, uint256) {
        unchecked {
            bytes memory lhs_ = new bytes(48);
            bytes memory rhs_ = new bytes(48);

            MemoryUtils.unsafeCopy(bytes_.getDataPointer(), lhs_.getDataPointer(), 48);
            MemoryUtils.unsafeCopy(bytes_.getDataPointer() + 48, rhs_.getDataPointer(), 48);

            return (_U384.fromBytes(lhs_), _U384.fromBytes(rhs_));
        }
    }
}
