// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library EC {
    struct Jpoint {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    function isOnCurve(
        uint256 x_,
        uint256 y_,
        uint256 a_,
        uint256 b_,
        uint256 p_
    ) internal pure returns (bool result_) {
        assembly ("memory-safe") {
            let lhs_ := mulmod(y_, y_, p_)
            let rhs_ := addmod(mulmod(addmod(mulmod(x_, x_, p_), a_, p_), x_, p_), b_, p_)

            result_ := and(and(lt(x_, p_), lt(y_, p_)), eq(lhs_, rhs_)) // Should conform with the Weierstrass equation
        }
    }

    function isValidScalar(uint256 u_, uint256 n_) internal pure returns (bool result_) {
        return u_ < n_;
    }

    function jEqual(
        Jpoint memory point1_,
        Jpoint memory point2_,
        uint256 p_
    ) internal view returns (bool result_) {
        (uint256 point1X_, uint256 point1Y_) = affineFromJacobian(point1_, p_);
        (uint256 point2X_, uint256 point2Y_) = affineFromJacobian(point2_, p_);

        return point1X_ == point2X_ && point1Y_ == point2Y_;
    }

    /**
     * @dev Reduce from jacobian to affine coordinates
     * @param point_ - point with jacobian coordinate x, y and z
     * @return ax_ - affine coordinate x
     * @return ay_ - affine coordinate y
     */
    function affineFromJacobian(
        Jpoint memory point_,
        uint256 p_
    ) internal view returns (uint256 ax_, uint256 ay_) {
        if (point_.z == 0) return (0, 0);

        uint256 zInverse_ = Math.invModPrime(point_.z, p_);

        assembly ("memory-safe") {
            let zzInverse_ := mulmod(zInverse_, zInverse_, p_)

            ax_ := mulmod(mload(point_), zzInverse_, p_)
            ay_ := mulmod(mload(add(point_, 0x20)), mulmod(zzInverse_, zInverse_, p_), p_)
        }
    }

    function jacobianFromAffine(
        uint256 x_,
        uint256 y_
    ) internal pure returns (Jpoint memory res_) {
        return Jpoint(x_, y_, 1);
    }

    function jacobianInfinity() internal pure returns (Jpoint memory res_) {
        return Jpoint(0, 0, 0);
    }

    function jMultShamir(
        Jpoint[16] memory points_,
        uint256 u_,
        uint256 p_,
        uint256 a_
    ) internal pure returns (Jpoint memory point_) {
        unchecked {
            for (uint256 i = 0; i < 64; ++i) {
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
                // Read 4 bits of u1 which corresponds to the lookup index in the table.
                uint256 pos_ = u_ >> 252;

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

                u_ <<= 4;
            }
        }
    }

    /**
     * @dev Compute G·u1 + P·u2 using the precomputed points for G and P (see {_preComputeJacobianPoints}).
     *
     * Uses Strauss Shamir trick for EC multiplication
     * https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method
     */
    function jMultShamir2(
        Jpoint[16] memory points_,
        uint256 u1_,
        uint256 u2_,
        uint256 p_,
        uint256 a_
    ) internal view returns (Jpoint memory point_) {
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
    }

    /**
     * @dev Precompute a matrice of useful jacobian points associated with a given P. This can be seen as a 4x4 matrix
     * that contains combination of P and G (generator) up to 3 times each
     */
    function preComputeJacobianPoints2(
        uint256 x_,
        uint256 y_,
        uint256 gx_,
        uint256 gy_,
        uint256 p_,
        uint256 a_
    ) internal pure returns (Jpoint[16] memory points_) {
        points_[0x00] = jacobianInfinity();
        points_[0x01] = jacobianFromAffine(x_, y_);
        points_[0x04] = jacobianFromAffine(gx_, gy_);
        points_[0x02] = jDoublePoint(points_[0x01], p_, a_);
        points_[0x08] = jDoublePoint(points_[0x04], p_, a_);
        points_[0x03] = jAddPoint(points_[0x01], points_[0x02], p_, a_);
        points_[0x05] = jAddPoint(points_[0x01], points_[0x04], p_, a_);
        points_[0x06] = jAddPoint(points_[0x02], points_[0x04], p_, a_);
        points_[0x07] = jAddPoint(points_[0x03], points_[0x04], p_, a_);
        points_[0x09] = jAddPoint(points_[0x01], points_[0x08], p_, a_);
        points_[0x0a] = jAddPoint(points_[0x02], points_[0x08], p_, a_);
        points_[0x0b] = jAddPoint(points_[0x03], points_[0x08], p_, a_);
        points_[0x0c] = jAddPoint(points_[0x04], points_[0x08], p_, a_);
        points_[0x0d] = jAddPoint(points_[0x01], points_[0x0c], p_, a_);
        points_[0x0e] = jAddPoint(points_[0x02], points_[0x0c], p_, a_);
        points_[0x0f] = jAddPoint(points_[0x03], points_[0x0c], p_, a_);
    }

    function preComputeJacobianPoints(
        uint256 x_,
        uint256 y_,
        uint256 p_,
        uint256 a_
    ) internal pure returns (Jpoint[16] memory points_) {
        points_[0x00] = jacobianInfinity();
        points_[0x01] = jacobianFromAffine(x_, y_);
        points_[0x02] = jDoublePoint(points_[0x01], p_, a_);
        points_[0x03] = jAddPoint(points_[0x01], points_[0x02], p_, a_);
        points_[0x04] = jAddPoint(points_[0x01], points_[0x03], p_, a_);
        points_[0x05] = jAddPoint(points_[0x01], points_[0x04], p_, a_);
        points_[0x06] = jAddPoint(points_[0x01], points_[0x05], p_, a_);
        points_[0x07] = jAddPoint(points_[0x01], points_[0x06], p_, a_);
        points_[0x08] = jAddPoint(points_[0x01], points_[0x07], p_, a_);
        points_[0x09] = jAddPoint(points_[0x01], points_[0x08], p_, a_);
        points_[0x0a] = jAddPoint(points_[0x01], points_[0x09], p_, a_);
        points_[0x0b] = jAddPoint(points_[0x01], points_[0x0a], p_, a_);
        points_[0x0c] = jAddPoint(points_[0x01], points_[0x0b], p_, a_);
        points_[0x0d] = jAddPoint(points_[0x01], points_[0x0c], p_, a_);
        points_[0x0e] = jAddPoint(points_[0x01], points_[0x0d], p_, a_);
        points_[0x0f] = jAddPoint(points_[0x01], points_[0x0e], p_, a_);

        //        points_[0x00] = jacobianFromAffine(0, 0);
        //        points_[0x01] = jacobianFromAffine(x_, y_);
        //        points_[0x02] = jDoublePoint(points_[0x01], p_, a_);
        //        points_[0x04] = jDoublePoint(points_[0x02], p_, a_);
        //        points_[0x08] = jDoublePoint(points_[0x04], p_, a_);
        //        points_[0x03] = jAddPoint(points_[0x01], points_[0x02], p_, a_);
        //        points_[0x06] = jDoublePoint(points_[0x03], p_, a_);
        //        points_[0x0c] = jDoublePoint(points_[0x06], p_, a_);
        //        points_[0x05] = jAddPoint(points_[0x01], points_[0x04], p_, a_);
        //        points_[0x0a] = jDoublePoint(points_[0x05], p_, a_);
        //        points_[0x07] = jAddPoint(points_[0x01], points_[0x06], p_, a_);
        //        points_[0x0e] = jDoublePoint(points_[0x07], p_, a_);
        //        points_[0x09] = jAddPoint(points_[0x01], points_[0x08], p_, a_);
        //        points_[0x0b] = jAddPoint(points_[0x01], points_[0x0a], p_, a_);
        //        points_[0x0d] = jAddPoint(points_[0x01], points_[0x0c], p_, a_);
        //        points_[0x0f] = jAddPoint(points_[0x01], points_[0x0e], p_, a_);
    }

    function jAddPoint(
        Jpoint memory point1_,
        Jpoint memory point2_,
        uint256 p_,
        uint256 a_
    ) internal pure returns (Jpoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jAdd(point1_, point2_, p_, a_);

        return Jpoint(x_, y_, z_);
    }

    function jDoublePoint(
        Jpoint memory point_,
        uint256 p_,
        uint256 a_
    ) internal pure returns (Jpoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jDouble(point_.x, point_.y, point_.z, p_, a_);

        return Jpoint(x_, y_, z_);
    }

    /**
     * @dev Point addition on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-add-1998-cmo-2
     */
    function _jAdd(
        Jpoint memory point1_,
        Jpoint memory point2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 resX_, uint256 resY_, uint256 resZ_) {
        assembly ("memory-safe") {
            let zz1_ := mulmod(mload(add(point1_, 0x40)), mload(add(point1_, 0x40)), p_)
            let s1_ := mulmod(
                mload(add(point1_, 0x20)),
                mulmod(
                    mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                    mload(add(point2_, 0x40)),
                    p_
                ),
                p_
            )
            let r_ := addmod(
                mulmod(mload(add(point2_, 0x20)), mulmod(zz1_, mload(add(point1_, 0x40)), p_), p_),
                sub(p_, s1_),
                p_
            )
            let u1_ := mulmod(
                mload(point1_),
                mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                p_
            )
            let h_ := addmod(mulmod(mload(point2_), zz1_, p_), sub(p_, u1_), p_)

            // detect edge cases where inputs are identical
            switch and(iszero(r_), iszero(h_))
            // case 0: points are different
            case 0 {
                let hh_ := mulmod(h_, h_, p_)

                resX_ := addmod(
                    addmod(mulmod(r_, r_, p_), sub(p_, mulmod(h_, hh_, p_)), p_),
                    sub(p_, mulmod(2, mulmod(u1_, hh_, p_), p_)),
                    p_
                )
                resY_ := addmod(
                    mulmod(r_, addmod(mulmod(u1_, hh_, p_), sub(p_, resX_), p_), p_),
                    sub(p_, mulmod(s1_, mulmod(h_, hh_, p_), p_)),
                    p_
                )
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
                let m_ := addmod(mulmod(3, xx_, p_), mulmod(a_, mulmod(zz_, zz_, p_), p_), p_)
                let s_ := mulmod(4, mulmod(mload(point2_), yy_, p_), p_)

                resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)

                // cut the computation to avoid stack too deep
                let rytmp1_ := sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_))
                let rytmp2_ := addmod(s_, sub(p_, resX_), p_)
                resY_ := addmod(mulmod(m_, rytmp2_, p_), rytmp1_, p_)

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
            )
            let s_ := mulmod(4, mulmod(x_, yy_, p_), p_)

            resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)
            resY_ := addmod(
                mulmod(m_, addmod(s_, sub(p_, resX_), p_), p_),
                sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_)),
                p_
            )
            resZ_ := mulmod(2, mulmod(y_, z_, p_), p_)
        }
    }
}
