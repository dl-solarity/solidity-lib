// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library EC256 {
    struct Curve {
        uint256 a;
        uint256 b;
        uint256 p;
        uint256 n;
        uint256 gx;
        uint256 gy;
    }

    struct Apoint {
        uint256 x;
        uint256 y;
    }

    struct Jpoint {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    function basepoint(Curve memory ec) internal pure returns (Apoint memory point_) {
        return Apoint(ec.gx, ec.gy);
    }

    function scalarFromU256(
        Curve memory ec,
        uint256 u256_
    ) internal pure returns (uint256 scalar_) {
        return u256_ % ec.n;
    }

    function isOnCurve(
        Curve memory ec,
        Apoint memory point_
    ) internal pure returns (bool result_) {
        return _isOnCurve(point_.x, point_.y, ec.a, ec.b, ec.p);
    }

    function isValidScalar(Curve memory ec, uint256 scalar_) internal pure returns (bool result_) {
        return scalar_ < ec.n;
    }

    function jEqual(
        Curve memory ec,
        Jpoint memory jPoint1_,
        Jpoint memory jPoint2_
    ) internal view returns (bool result_) {
        Apoint memory aPoint1_ = affineFromJacobian(ec, jPoint1_);
        Apoint memory aPoint2_ = affineFromJacobian(ec, jPoint2_);

        return aPoint1_.x == aPoint2_.x && aPoint1_.y == aPoint2_.y;
    }

    /**
     * @dev Reduce from jacobian to affine coordinates
     * @param jPoint_ point with jacobian coordinate x, y and z
     * @return aPoint_ point with affine coordinate x and y
     */
    function affineFromJacobian(
        Curve memory ec,
        Jpoint memory jPoint_
    ) internal view returns (Apoint memory aPoint_) {
        (aPoint_.x, aPoint_.y) = _affineFromJacobian(jPoint_, ec.p);
    }

    function jacobianFromAffine(Apoint memory aPoint_) internal pure returns (Jpoint memory res_) {
        return Jpoint(aPoint_.x, aPoint_.y, 1);
    }

    function isJacobianInfinity(Jpoint memory point_) internal pure returns (bool res_) {
        return point_.z == 0;
    }

    function jacobianInfinity() internal pure returns (Jpoint memory res_) {
        return Jpoint(0, 0, 0);
    }

    function jMultShamir(
        Curve memory ec,
        Jpoint[16] memory points_,
        uint256 u_
    ) internal pure returns (Jpoint memory point_) {
        unchecked {
            for (uint256 i = 0; i < 64; ++i) {
                point_ = jDoublePoint(ec, point_);
                point_ = jDoublePoint(ec, point_);
                point_ = jDoublePoint(ec, point_);
                point_ = jDoublePoint(ec, point_);

                // Read 4 bits of u1 which corresponds to the lookup index in the table.
                uint256 pos_ = u_ >> 252;
                u_ <<= 4;

                point_ = jAddPoint(ec, points_[pos_], point_);
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
        Curve memory ec,
        Jpoint[16] memory points_,
        uint256 scalar1_,
        uint256 scalar2_
    ) internal view returns (Jpoint memory point_) {
        unchecked {
            for (uint256 i = 0; i < 128; ++i) {
                point_ = jDoublePoint(ec, point_);
                point_ = jDoublePoint(ec, point_);

                // Read 2 bits of u1, and 2 bits of u2. Combining the two gives the lookup index in the table.
                uint256 pos_ = ((scalar1_ >> 252) & 0xc) | ((scalar2_ >> 254) & 0x3);
                scalar1_ <<= 2;
                scalar2_ <<= 2;

                point_ = jAddPoint(ec, points_[pos_], point_);
            }
        }
    }

    function preComputeJacobianPoints(
        Curve memory ec,
        Apoint memory point_
    ) internal pure returns (Jpoint[16] memory points_) {
        points_[0x00] = jacobianInfinity();
        points_[0x01] = jacobianFromAffine(point_);
        points_[0x02] = jDoublePoint(ec, points_[0x01]);
        points_[0x04] = jDoublePoint(ec, points_[0x02]);
        points_[0x08] = jDoublePoint(ec, points_[0x04]);
        points_[0x03] = jAddPoint(ec, points_[0x01], points_[0x02]);
        points_[0x06] = jDoublePoint(ec, points_[0x03]);
        points_[0x0c] = jDoublePoint(ec, points_[0x06]);
        points_[0x05] = jAddPoint(ec, points_[0x01], points_[0x04]);
        points_[0x0a] = jDoublePoint(ec, points_[0x05]);
        points_[0x07] = jAddPoint(ec, points_[0x01], points_[0x06]);
        points_[0x0e] = jDoublePoint(ec, points_[0x07]);
        points_[0x09] = jAddPoint(ec, points_[0x01], points_[0x08]);
        points_[0x0b] = jAddPoint(ec, points_[0x01], points_[0x0a]);
        points_[0x0d] = jAddPoint(ec, points_[0x01], points_[0x0c]);
        points_[0x0f] = jAddPoint(ec, points_[0x01], points_[0x0e]);
    }

    /**
     * @dev Precompute a matrice of useful jacobian points associated with a given P. This can be seen as a 4x4 matrix
     * that contains combination of P and G (generator) up to 3 times each
     */
    function preComputeJacobianPoints2(
        Curve memory ec,
        Apoint memory point1_,
        Apoint memory point2_
    ) internal pure returns (Jpoint[16] memory points_) {
        points_[0x00] = jacobianInfinity();
        points_[0x01] = jacobianFromAffine(point1_);
        points_[0x04] = jacobianFromAffine(point2_);
        points_[0x02] = jDoublePoint(ec, points_[0x01]);
        points_[0x08] = jDoublePoint(ec, points_[0x04]);
        points_[0x03] = jAddPoint(ec, points_[0x01], points_[0x02]);
        points_[0x05] = jAddPoint(ec, points_[0x01], points_[0x04]);
        points_[0x06] = jAddPoint(ec, points_[0x02], points_[0x04]);
        points_[0x07] = jAddPoint(ec, points_[0x03], points_[0x04]);
        points_[0x09] = jAddPoint(ec, points_[0x01], points_[0x08]);
        points_[0x0a] = jAddPoint(ec, points_[0x02], points_[0x08]);
        points_[0x0b] = jAddPoint(ec, points_[0x03], points_[0x08]);
        points_[0x0c] = jAddPoint(ec, points_[0x04], points_[0x08]);
        points_[0x0d] = jAddPoint(ec, points_[0x01], points_[0x0c]);
        points_[0x0e] = jAddPoint(ec, points_[0x02], points_[0x0c]);
        points_[0x0f] = jAddPoint(ec, points_[0x03], points_[0x0c]);
    }

    function jAddPoint(
        Curve memory ec,
        Jpoint memory point1_,
        Jpoint memory point2_
    ) internal pure returns (Jpoint memory) {
        if (isJacobianInfinity(point1_)) {
            return Jpoint(point2_.x, point2_.y, point2_.z);
        }

        if (isJacobianInfinity(point2_)) {
            return Jpoint(point1_.x, point1_.y, point1_.z);
        }

        (uint256 x_, uint256 y_, uint256 z_) = _jAdd(point1_, point2_, ec.p, ec.a);

        return Jpoint(x_, y_, z_);
    }

    function jDoublePoint(
        Curve memory ec,
        Jpoint memory point_
    ) internal pure returns (Jpoint memory) {
        if (isJacobianInfinity(point_)) {
            return Jpoint(point_.x, point_.y, point_.z);
        }

        (uint256 x_, uint256 y_, uint256 z_) = _jDouble(point_.x, point_.y, point_.z, ec.p, ec.a);

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

    function _affineFromJacobian(
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

    function _isOnCurve(
        uint256 x_,
        uint256 y_,
        uint256 a_,
        uint256 b_,
        uint256 p_
    ) private pure returns (bool result_) {
        assembly ("memory-safe") {
            let lhs_ := mulmod(y_, y_, p_)
            let rhs_ := addmod(mulmod(addmod(mulmod(x_, x_, p_), a_, p_), x_, p_), b_, p_)

            // Should conform with the Weierstrass equation
            result_ := and(and(lt(x_, p_), lt(y_, p_)), eq(lhs_, rhs_))
        }
    }
}
