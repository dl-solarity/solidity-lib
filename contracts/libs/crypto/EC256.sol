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

    function basepoint(Curve memory ec) internal pure returns (Apoint memory aPoint_) {
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
        Apoint memory aPoint_
    ) internal pure returns (bool result_) {
        return _isOnCurve(aPoint_.x, aPoint_.y, ec.a, ec.b, ec.p);
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

    function jacobianFromAffine(
        Apoint memory aPoint_
    ) internal pure returns (Jpoint memory jPoint_) {
        return Jpoint(aPoint_.x, aPoint_.y, 1);
    }

    function isJacobianInfinity(Jpoint memory jPoint_) internal pure returns (bool result_) {
        return jPoint_.z == 0;
    }

    function jacobianInfinity() internal pure returns (Jpoint memory jPoint_) {
        return Jpoint(0, 0, 0);
    }

    function jMultShamir(
        Curve memory ec,
        Jpoint memory jPoint_,
        uint256 u_
    ) internal pure returns (Jpoint memory jPoint2_) {
        unchecked {
            Jpoint[16] memory jPoints_ = _preComputeJacobianPoints(ec, jPoint_);

            for (uint256 i = 0; i < 64; ++i) {
                jPoint2_ = jDoublePoint(ec, jPoint2_);
                jPoint2_ = jDoublePoint(ec, jPoint2_);
                jPoint2_ = jDoublePoint(ec, jPoint2_);
                jPoint2_ = jDoublePoint(ec, jPoint2_);

                // Read 4 bits of u1 which corresponds to the lookup index in the table.
                uint256 pos_ = u_ >> 252;
                u_ <<= 4;

                jPoint2_ = jAddPoint(ec, jPoints_[pos_], jPoint2_);
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
        Jpoint memory jPoint1_,
        Jpoint memory jPoint2_,
        uint256 scalar1_,
        uint256 scalar2_
    ) internal pure returns (Jpoint memory jPoint3_) {
        unchecked {
            Jpoint[16] memory jPoints_ = _preComputeJacobianPoints2(ec, jPoint1_, jPoint2_);

            for (uint256 i = 0; i < 128; ++i) {
                jPoint3_ = jDoublePoint(ec, jPoint3_);
                jPoint3_ = jDoublePoint(ec, jPoint3_);

                // Read 2 bits of u1, and 2 bits of u2. Combining the two gives the lookup index in the table.
                uint256 pos_ = ((scalar1_ >> 252) & 0xc) | ((scalar2_ >> 254) & 0x3);
                scalar1_ <<= 2;
                scalar2_ <<= 2;

                jPoint3_ = jAddPoint(ec, jPoints_[pos_], jPoint3_);
            }
        }
    }

    function jAddPoint(
        Curve memory ec,
        Jpoint memory jPoint1_,
        Jpoint memory jPoint2_
    ) internal pure returns (Jpoint memory jPoint3_) {
        if (isJacobianInfinity(jPoint1_)) {
            return Jpoint(jPoint2_.x, jPoint2_.y, jPoint2_.z);
        }

        if (isJacobianInfinity(jPoint2_)) {
            return Jpoint(jPoint1_.x, jPoint1_.y, jPoint1_.z);
        }

        (uint256 x_, uint256 y_, uint256 z_) = _jAdd(jPoint1_, jPoint2_, ec.p, ec.a);

        return Jpoint(x_, y_, z_);
    }

    function jDoublePoint(
        Curve memory ec,
        Jpoint memory jPoint1_
    ) internal pure returns (Jpoint memory jPoint2_) {
        if (isJacobianInfinity(jPoint1_)) {
            return Jpoint(jPoint1_.x, jPoint1_.y, jPoint1_.z);
        }

        (uint256 x_, uint256 y_, uint256 z_) = _jDouble(
            jPoint1_.x,
            jPoint1_.y,
            jPoint1_.z,
            ec.p,
            ec.a
        );

        return Jpoint(x_, y_, z_);
    }

    /**
     * @dev Point addition on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-add-1998-cmo-2
     */
    function _jAdd(
        Jpoint memory jPoint1_,
        Jpoint memory jPoint2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 jx3_, uint256 jy3_, uint256 jz3_) {
        assembly ("memory-safe") {
            let zz1_ := mulmod(mload(add(jPoint1_, 0x40)), mload(add(jPoint1_, 0x40)), p_)
            let s1_ := mulmod(
                mload(add(jPoint1_, 0x20)),
                mulmod(
                    mulmod(mload(add(jPoint2_, 0x40)), mload(add(jPoint2_, 0x40)), p_),
                    mload(add(jPoint2_, 0x40)),
                    p_
                ),
                p_
            )
            let r_ := addmod(
                mulmod(
                    mload(add(jPoint2_, 0x20)),
                    mulmod(zz1_, mload(add(jPoint1_, 0x40)), p_),
                    p_
                ),
                sub(p_, s1_),
                p_
            )
            let u1_ := mulmod(
                mload(jPoint1_),
                mulmod(mload(add(jPoint2_, 0x40)), mload(add(jPoint2_, 0x40)), p_),
                p_
            )
            let h_ := addmod(mulmod(mload(jPoint2_), zz1_, p_), sub(p_, u1_), p_)

            // detect edge cases where inputs are identical
            switch and(iszero(r_), iszero(h_))
            // case 0: points are different
            case 0 {
                let hh_ := mulmod(h_, h_, p_)

                jx3_ := addmod(
                    addmod(mulmod(r_, r_, p_), sub(p_, mulmod(h_, hh_, p_)), p_),
                    sub(p_, mulmod(2, mulmod(u1_, hh_, p_), p_)),
                    p_
                )
                jy3_ := addmod(
                    mulmod(r_, addmod(mulmod(u1_, hh_, p_), sub(p_, jx3_), p_), p_),
                    sub(p_, mulmod(s1_, mulmod(h_, hh_, p_), p_)),
                    p_
                )
                jz3_ := mulmod(
                    h_,
                    mulmod(mload(add(jPoint1_, 0x40)), mload(add(jPoint2_, 0x40)), p_),
                    p_
                )
            }
            // case 1: points are equal
            case 1 {
                let yy_ := mulmod(mload(add(jPoint2_, 0x20)), mload(add(jPoint2_, 0x20)), p_)
                let zz_ := mulmod(mload(add(jPoint2_, 0x40)), mload(add(jPoint2_, 0x40)), p_)
                let xx_ := mulmod(mload(jPoint2_), mload(jPoint2_), p_)
                let m_ := addmod(mulmod(3, xx_, p_), mulmod(a_, mulmod(zz_, zz_, p_), p_), p_)
                let s_ := mulmod(4, mulmod(mload(jPoint2_), yy_, p_), p_)

                jx3_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)

                // cut the computation to avoid stack too deep
                let rytmp1_ := sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_))
                let rytmp2_ := addmod(s_, sub(p_, jx3_), p_)
                jy3_ := addmod(mulmod(m_, rytmp2_, p_), rytmp1_, p_)

                jz3_ := mulmod(
                    2,
                    mulmod(mload(add(jPoint2_, 0x20)), mload(add(jPoint2_, 0x40)), p_),
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
        uint256 jx1_,
        uint256 jy1_,
        uint256 jz1_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 jx2_, uint256 jy2_, uint256 jz2_) {
        assembly ("memory-safe") {
            let yy_ := mulmod(jy1_, jy1_, p_)
            let zz_ := mulmod(jz1_, jz1_, p_)
            let m_ := addmod(
                mulmod(3, mulmod(jx1_, jx1_, p_), p_),
                mulmod(a_, mulmod(zz_, zz_, p_), p_),
                p_
            )
            let s_ := mulmod(4, mulmod(jx1_, yy_, p_), p_)

            jx2_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)
            jy2_ := addmod(
                mulmod(m_, addmod(s_, sub(p_, jx2_), p_), p_),
                sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_)),
                p_
            )
            jz2_ := mulmod(2, mulmod(jy1_, jz1_, p_), p_)
        }
    }

    function _affineFromJacobian(
        Jpoint memory jPoint_,
        uint256 p_
    ) private view returns (uint256 ax_, uint256 ay_) {
        if (jPoint_.z == 0) return (0, 0);

        uint256 zInverse_ = Math.invModPrime(jPoint_.z, p_);

        assembly ("memory-safe") {
            let zzInverse_ := mulmod(zInverse_, zInverse_, p_)

            ax_ := mulmod(mload(jPoint_), zzInverse_, p_)
            ay_ := mulmod(mload(add(jPoint_, 0x20)), mulmod(zzInverse_, zInverse_, p_), p_)
        }
    }

    function _isOnCurve(
        uint256 ax_,
        uint256 ay_,
        uint256 a_,
        uint256 b_,
        uint256 p_
    ) private pure returns (bool result_) {
        assembly ("memory-safe") {
            let lhs_ := mulmod(ay_, ay_, p_)
            let rhs_ := addmod(mulmod(addmod(mulmod(ax_, ax_, p_), a_, p_), ax_, p_), b_, p_)

            // Should conform with the Weierstrass equation
            result_ := and(and(lt(ax_, p_), lt(ay_, p_)), eq(lhs_, rhs_))
        }
    }

    function _preComputeJacobianPoints(
        Curve memory ec,
        Jpoint memory jPoint_
    ) private pure returns (Jpoint[16] memory jPoints_) {
        jPoints_[0x00] = jacobianInfinity();
        jPoints_[0x01] = Jpoint(jPoint_.x, jPoint_.y, jPoint_.z);
        jPoints_[0x02] = jDoublePoint(ec, jPoints_[0x01]);
        jPoints_[0x04] = jDoublePoint(ec, jPoints_[0x02]);
        jPoints_[0x08] = jDoublePoint(ec, jPoints_[0x04]);
        jPoints_[0x03] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x02]);
        jPoints_[0x06] = jDoublePoint(ec, jPoints_[0x03]);
        jPoints_[0x0c] = jDoublePoint(ec, jPoints_[0x06]);
        jPoints_[0x05] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x04]);
        jPoints_[0x0a] = jDoublePoint(ec, jPoints_[0x05]);
        jPoints_[0x07] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x06]);
        jPoints_[0x0e] = jDoublePoint(ec, jPoints_[0x07]);
        jPoints_[0x09] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x08]);
        jPoints_[0x0b] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x0a]);
        jPoints_[0x0d] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x0c]);
        jPoints_[0x0f] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x0e]);
    }

    /**
     * @dev Precompute a matrice of useful jacobian points associated with a given P. This can be seen as a 4x4 matrix
     * that contains combination of P and G (generator) up to 3 times each
     */
    function _preComputeJacobianPoints2(
        Curve memory ec,
        Jpoint memory jPoint1_,
        Jpoint memory jPoint2_
    ) private pure returns (Jpoint[16] memory jPoints_) {
        jPoints_[0x00] = jacobianInfinity();
        jPoints_[0x01] = Jpoint(jPoint1_.x, jPoint1_.y, jPoint1_.z);
        jPoints_[0x04] = Jpoint(jPoint2_.x, jPoint2_.y, jPoint2_.z);
        jPoints_[0x02] = jDoublePoint(ec, jPoints_[0x01]);
        jPoints_[0x08] = jDoublePoint(ec, jPoints_[0x04]);
        jPoints_[0x03] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x02]);
        jPoints_[0x05] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x04]);
        jPoints_[0x06] = jAddPoint(ec, jPoints_[0x02], jPoints_[0x04]);
        jPoints_[0x07] = jAddPoint(ec, jPoints_[0x03], jPoints_[0x04]);
        jPoints_[0x09] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x08]);
        jPoints_[0x0a] = jAddPoint(ec, jPoints_[0x02], jPoints_[0x08]);
        jPoints_[0x0b] = jAddPoint(ec, jPoints_[0x03], jPoints_[0x08]);
        jPoints_[0x0c] = jAddPoint(ec, jPoints_[0x04], jPoints_[0x08]);
        jPoints_[0x0d] = jAddPoint(ec, jPoints_[0x01], jPoints_[0x0c]);
        jPoints_[0x0e] = jAddPoint(ec, jPoints_[0x02], jPoints_[0x0c]);
        jPoints_[0x0f] = jAddPoint(ec, jPoints_[0x03], jPoints_[0x0c]);
    }
}
