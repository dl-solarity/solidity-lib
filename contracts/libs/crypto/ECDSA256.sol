// SPDX-License-Identifier: MIT
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/cryptography/P256.sol
pragma solidity ^0.8.4;

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 256-bit curve.
 *
 * For more information, please refer to the OpenZeppelin documentation.
 */
library ECDSA256 {
    /**
     * @notice 256-bit curve parameters.
     */
    struct Parameters {
        uint256 a;
        uint256 b;
        uint256 gx;
        uint256 gy;
        uint256 p;
        uint256 n;
        uint256 lowSmax;
    }

    struct _JPoint {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    struct _Inputs {
        uint256 r;
        uint256 s;
        uint256 x;
        uint256 y;
    }

    /**
     * @notice The function to verify the ECDSA signature
     * @param curveParams_ the 256-bit curve parameters. `lowSmax` is `n / 2`.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s > n / 2`, change it to `s = n - s`.
     */
    function verify(
        Parameters memory curveParams_,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            _Inputs memory inputs_;

            (inputs_.r, inputs_.s) = _split(signature_);
            (inputs_.x, inputs_.y) = _split(pubKey_);

            if (
                !isProperSignature(inputs_.r, inputs_.s, curveParams_.n, curveParams_.lowSmax) ||
                !isValidPublicKey(
                    inputs_.x,
                    inputs_.y,
                    curveParams_.a,
                    curveParams_.b,
                    curveParams_.p
                )
            ) {
                return false;
            }

            uint256 u1_;
            uint256 u2_;

            {
                uint256 w_ = _invModPrime(inputs_.s, curveParams_.n);
                u1_ = mulmod(uint256(hashedMessage_), w_, curveParams_.n);
                u2_ = mulmod(inputs_.r, w_, curveParams_.n);
            }

            uint256 x_;

            {
                _JPoint[16] memory points_ = _preComputeJacobianPoints(
                    inputs_.x,
                    inputs_.y,
                    curveParams_.gx,
                    curveParams_.gy,
                    curveParams_.p,
                    curveParams_.a
                );

                (x_, ) = _jMultShamir(points_, u1_, u2_, curveParams_.p, curveParams_.a);
            }

            return ((x_ % curveParams_.n) == inputs_.r);
        }
    }

    /**
     * @dev Checks if (x, y) are valid coordinates of a point on the curve.
     * In particular this function checks that x < P and y < P.
     */
    function isValidPublicKey(
        uint256 x_,
        uint256 y_,
        uint256 a_,
        uint256 b_,
        uint256 p_
    ) internal pure returns (bool result_) {
        assembly ("memory-safe") {
            let lhs_ := mulmod(y_, y_, p_) // y^2
            let rhs_ := addmod(mulmod(addmod(mulmod(x_, x_, p_), a_, p_), x_, p_), b_, p_) // ((x^2 + a) * x) + b = x^3 + ax + b

            result_ := and(and(lt(x_, p_), lt(y_, p_)), eq(lhs_, rhs_)) // Should conform with the Weierstrass equation
        }
    }

    /**
     * @dev Checks if (r, s) is a proper signature.
     * In particular, this checks that `s` is in the "lower-range", making the signature non-malleable
     */
    function isProperSignature(
        uint256 r_,
        uint256 s_,
        uint256 n_,
        uint256 lowSmax_
    ) internal pure returns (bool) {
        return r_ > 0 && r_ < n_ && s_ > 0 && s_ <= lowSmax_;
    }

    /**
     * @dev Reduce from jacobian to affine coordinates
     * @param point_ - point with jacobian coordinate x, y and z
     * @return ax_ - affine coordinate x
     * @return ay_ - affine coordinate y
     */
    function _affineFromJacobian(
        _JPoint memory point_,
        uint256 p_
    ) private view returns (uint256 ax_, uint256 ay_) {
        if (point_.z == 0) return (0, 0);

        uint256 zInverse_ = _invModPrime(point_.z, p_);

        assembly ("memory-safe") {
            let zzInverse_ := mulmod(zInverse_, zInverse_, p_)

            ax_ := mulmod(mload(point_), zzInverse_, p_)
            ay_ := mulmod(mload(add(point_, 0x20)), mulmod(zzInverse_, zInverse_, p_), p_)
        }
    }

    /**
     * @dev Point addition on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-add-1998-cmo-2
     */
    function _jAdd(
        _JPoint memory point1_,
        _JPoint memory point2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 resX_, uint256 resY_, uint256 resZ_) {
        assembly ("memory-safe") {
            let zz1_ := mulmod(mload(add(point1_, 0x40)), mload(add(point1_, 0x40)), p_) // zz1 = z1²
            let s1_ := mulmod(
                mload(add(point1_, 0x20)),
                mulmod(
                    mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                    mload(add(point2_, 0x40)),
                    p_
                ),
                p_
            ) // s1 = y1*z2³
            let r_ := addmod(
                mulmod(mload(add(point2_, 0x20)), mulmod(zz1_, mload(add(point1_, 0x40)), p_), p_),
                sub(p_, s1_),
                p_
            ) // r = s2-s1 = y2*z1³-s1 = y2*z1³-y1*z2³
            let u1_ := mulmod(
                mload(point1_),
                mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                p_
            ) // u1 = x1*z2²
            let h_ := addmod(mulmod(mload(point2_), zz1_, p_), sub(p_, u1_), p_) // h = u2-u1 = x2*z1²-u1 = x2*z1²-x1*z2²

            // detect edge cases where inputs are identical
            switch and(iszero(r_), iszero(h_))
            // case 0: points are different
            case 0 {
                let hh_ := mulmod(h_, h_, p_) // h²

                // x' = r²-h³-2*u1*h²
                resX_ := addmod(
                    addmod(mulmod(r_, r_, p_), sub(p_, mulmod(h_, hh_, p_)), p_),
                    sub(p_, mulmod(2, mulmod(u1_, hh_, p_), p_)),
                    p_
                )
                // y' = r*(u1*h²-x')-s1*h³
                resY_ := addmod(
                    mulmod(r_, addmod(mulmod(u1_, hh_, p_), sub(p_, resX_), p_), p_),
                    sub(p_, mulmod(s1_, mulmod(h_, hh_, p_), p_)),
                    p_
                )
                // z' = h*z1*z2
                resZ_ := mulmod(
                    h_,
                    mulmod(mload(add(point1_, 0x40)), mload(add(point2_, 0x40)), p_),
                    p_
                )
            }
            // case 1: points are equal
            case 1 {
                let yy_ := mulmod(mload(add(point2_, 0x20)), mload(add(point2_, 0x20)), p_)
                let zz_ := mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_)
                let xx_ := mulmod(mload(point2_), mload(point2_), p_)
                let m_ := addmod(mulmod(3, xx_, p_), mulmod(a_, mulmod(zz_, zz_, p_), p_), p_) // m = 3*x²+a*z⁴
                let s_ := mulmod(4, mulmod(mload(point2_), yy_, p_), p_) // s = 4*x*y²

                // x' = t = m²-2*s
                resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)

                // y' = m*(s-t)-8*y⁴ = m*(s-x')-8*y⁴
                // cut the computation to avoid stack too deep
                let rytmp1_ := sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_)) // -8*y⁴
                let rytmp2_ := addmod(s_, sub(p_, resX_), p_) // s-x'
                resY_ := addmod(mulmod(m_, rytmp2_, p_), rytmp1_, p_) // m*(s-x')-8*y⁴

                // z' = 2*y*z
                resZ_ := mulmod(
                    2,
                    mulmod(mload(add(point2_, 0x20)), mload(add(point2_, 0x40)), p_),
                    p_
                )
            }
        }
    }

    /**
     * @dev Point doubling on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#doubling-dbl-1998-cmo-2
     */
    function _jDouble(
        uint256 x_,
        uint256 y_,
        uint256 z_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 resX_, uint256 resY_, uint256 resZ_) {
        assembly ("memory-safe") {
            let yy_ := mulmod(y_, y_, p_)
            let zz_ := mulmod(z_, z_, p_)
            let m_ := addmod(
                mulmod(3, mulmod(x_, x_, p_), p_),
                mulmod(a_, mulmod(zz_, zz_, p_), p_),
                p_
            ) // m = 3*x²+a*z⁴
            let s_ := mulmod(4, mulmod(x_, yy_, p_), p_) // s = 4*x*y²

            // x' = t = m²-2*s
            resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)
            // y' = m*(s-t)-8*y⁴ = m*(s-x')-8*y⁴
            resY_ := addmod(
                mulmod(m_, addmod(s_, sub(p_, resX_), p_), p_),
                sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_)),
                p_
            )
            // z' = 2*y*z
            resZ_ := mulmod(2, mulmod(y_, z_, p_), p_)
        }
    }

    /**
     * @dev Compute G·u1 + P·u2 using the precomputed points for G and P (see {_preComputeJacobianPoints}).
     *
     * Uses Strauss Shamir trick for EC multiplication
     * https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method
     */
    function _jMultShamir(
        _JPoint[16] memory points_,
        uint256 u1_,
        uint256 u2_,
        uint256 p_,
        uint256 a_
    ) private view returns (uint256 resX_, uint256 resY_) {
        _JPoint memory point_;

        unchecked {
            for (uint256 i = 0; i < 128; ++i) {
                if (point_.z > 0) {
                    (point_.x, point_.y, point_.z) = _jDouble(
                        point_.x,
                        point_.y,
                        point_.z,
                        p_,
                        a_
                    );
                    (point_.x, point_.y, point_.z) = _jDouble(
                        point_.x,
                        point_.y,
                        point_.z,
                        p_,
                        a_
                    );
                }
                // Read 2 bits of u1, and 2 bits of u2. Combining the two gives the lookup index in the table.
                uint256 pos_ = ((u1_ >> 252) & 0xc) | ((u2_ >> 254) & 0x3);
                // Points that have z = 0 are points at infinity. They are the additive 0 of the group
                // - if the lookup point is a 0, we can skip it
                // - otherwise:
                //   - if the current point (x, y, z) is 0, we use the lookup point as our new value (0+P=P)
                //   - if the current point (x, y, z) is not 0, both points are valid and we can use `_jAdd`
                if (points_[pos_].z != 0) {
                    if (point_.z == 0) {
                        (point_.x, point_.y, point_.z) = (
                            points_[pos_].x,
                            points_[pos_].y,
                            points_[pos_].z
                        );
                    } else {
                        (point_.x, point_.y, point_.z) = _jAdd(points_[pos_], point_, p_, a_);
                    }
                }
                u1_ <<= 2;
                u2_ <<= 2;
            }
        }
        return _affineFromJacobian(point_, p_);
    }

    /**
     * @dev Precompute a matrice of useful jacobian points associated with a given P. This can be seen as a 4x4 matrix
     * that contains combination of P and G (generator) up to 3 times each
     */
    function _preComputeJacobianPoints(
        uint256 x_,
        uint256 y_,
        uint256 gx_,
        uint256 gy_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint[16] memory points_) {
        points_[0x00] = _JPoint(0, 0, 0); // 0,0
        points_[0x01] = _JPoint(x_, y_, 1); // 1,0 (p)
        points_[0x04] = _JPoint(gx_, gy_, 1); // 0,1 (g)
        points_[0x02] = _jDoublePoint(points_[0x01], p_, a_); // 2,0 (2p)
        points_[0x08] = _jDoublePoint(points_[0x04], p_, a_); // 0,2 (2g)
        points_[0x03] = _jAddPoint(points_[0x01], points_[0x02], p_, a_); // 3,0 (p+2p = 3p)
        points_[0x05] = _jAddPoint(points_[0x01], points_[0x04], p_, a_); // 1,1 (p+g)
        points_[0x06] = _jAddPoint(points_[0x02], points_[0x04], p_, a_); // 2,1 (2p+g)
        points_[0x07] = _jAddPoint(points_[0x03], points_[0x04], p_, a_); // 3,1 (3p+g)
        points_[0x09] = _jAddPoint(points_[0x01], points_[0x08], p_, a_); // 1,2 (p+2g)
        points_[0x0a] = _jAddPoint(points_[0x02], points_[0x08], p_, a_); // 2,2 (2p+2g)
        points_[0x0b] = _jAddPoint(points_[0x03], points_[0x08], p_, a_); // 3,2 (3p+2g)
        points_[0x0c] = _jAddPoint(points_[0x04], points_[0x08], p_, a_); // 0,3 (g+2g = 3g)
        points_[0x0d] = _jAddPoint(points_[0x01], points_[0x0c], p_, a_); // 1,3 (p+3g)
        points_[0x0e] = _jAddPoint(points_[0x02], points_[0x0c], p_, a_); // 2,3 (2p+3g)
        points_[0x0f] = _jAddPoint(points_[0x03], points_[0x0c], p_, a_); // 3,3 (3p+3g)
    }

    function _jAddPoint(
        _JPoint memory point1_,
        _JPoint memory point2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jAdd(point1_, point2_, p_, a_);

        return _JPoint(x_, y_, z_);
    }

    function _jDoublePoint(
        _JPoint memory point_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jDouble(point_.x, point_.y, point_.z, p_, a_);

        return _JPoint(x_, y_, z_);
    }

    /**
     * @dev Helper function for splitting bytes into two uint256 values. Used for 64-byte signatures and public keys
     */
    function _split(
        bytes memory from2_
    ) private pure returns (uint256 leftPart_, uint256 rightPart_) {
        unchecked {
            require(from2_.length == 64, "ECDSA256: length is not 64");

            assembly ("memory-safe") {
                leftPart_ := mload(add(from2_, 32))
                rightPart_ := mload(add(from2_, 64))
            }

            return (leftPart_, rightPart_);
        }
    }

    /**
     * @dev Calculate the modular multiplicative inverse, only works if `modulus_` is known to be a prime greater than `2`
     *
     * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/math/Math.sol#L300.
     * For more information, please refer to the OpenZeppelin documentation.
     */
    function _invModPrime(uint256 base_, uint256 modulus_) private view returns (uint256) {
        unchecked {
            return _modExp(base_, modulus_ - 2, modulus_);
        }
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m).
     *
     * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/math/Math.sol#L319.
     * For more information, please refer to the OpenZeppelin documentation
     */
    function _modExp(
        uint256 base_,
        uint256 exponent_,
        uint256 modulus_
    ) private view returns (uint256) {
        (bool success_, uint256 result_) = _tryModExp(base_, exponent_, modulus_);

        require(success_, "ECDSA256: division by zero");

        return result_;
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m).
     * It includes a success flag indicating if the operation succeeded. Operation will be marked as failed if trying
     * to operate modulo 0 or if the underlying precompile reverted.
     *
     * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/math/Math.sol#L337.
     * For more information, please refer to the OpenZeppelin documentation
     */
    function _tryModExp(
        uint256 base_,
        uint256 exponent_,
        uint256 modulus_
    ) private view returns (bool success_, uint256 result_) {
        if (modulus_ == 0) return (false, 0);

        assembly ("memory-safe") {
            let pointer_ := mload(0x40)

            mstore(pointer_, 0x20)
            mstore(add(pointer_, 0x20), 0x20)
            mstore(add(pointer_, 0x40), 0x20)
            mstore(add(pointer_, 0x60), base_)
            mstore(add(pointer_, 0x80), exponent_)
            mstore(add(pointer_, 0xa0), modulus_)

            success_ := staticcall(gas(), 0x05, pointer_, 0xc0, 0x00, 0x20)
            result_ := mload(0x00)
        }
    }
}
