// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice Cryptography module
 *
 * Elliptic curve arithmetic over a 256-bit prime field (Twisted Edwards curve ax^2 + y^2 = 1 +dx^2y^2 (mod p)).
 */
library ECEdwards {
    /**
     * @notice 256-bit curve parameters.
     * @param a The curve coefficient a.
     * @param d The curve coefficient d.
     * @param p The base field size.
     * @param n The scalar field size.
     * @param gx The x-coordinate of the basepoint G.
     * @param gy The y-coordinate of the basepoint G.
     */
    struct Curve {
        uint256 a;
        uint256 d;
        uint256 p;
        uint256 n;
        uint256 gx;
        uint256 gy;
    }

    /**
     * @notice Affine representation of a curve point.
     * @param x The x-coordinate.
     * @param y The y-coordinate.
     */
    struct APoint {
        uint256 x;
        uint256 y;
    }

    /**
     * @notice Projective representation of a curve point.
     * @param x The projective X coordinate.
     * @param y The projective Y coordinate.
     * @param z The projective Z coordinate.
     */
    struct PPoint {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    /**
     * @notice Returns the generator (base) point of the curve in affine form.
     * @param ec The curve parameters.
     * @return aPoint_ The basepoint (gx, gy).
     */
    function basepoint(Curve memory ec) internal pure returns (APoint memory aPoint_) {
        return APoint(ec.gx, ec.gy);
    }

    /**
     * @notice Returns the generator (base) point of the curve in projective form.
     * @param ec The curve parameters.
     * @return pPoint_ The basepoint (gx, gy, 1).
     */
    function pBasepoint(Curve memory ec) internal pure returns (PPoint memory pPoint_) {
        return PPoint(ec.gx, ec.gy, 1);
    }

    /**
     * @notice Reduces an arbitrary uint256 into the scalar field [0, n).
     * @param ec The curve parameters.
     * @param u256_ The integer to reduce.
     * @return scalar_ The result of u256_ mod n.
     */
    function toScalar(Curve memory ec, uint256 u256_) internal pure returns (uint256 scalar_) {
        return u256_ % ec.n;
    }

    /**
     * @notice Checks whether an affine point lies on the curve.
     * @param ec The curve parameters.
     * @param aPoint_ The affine point to test.
     * @return result_ True if `aPoint_` satisfies ax^2 + y^2 = 1 + dx^2y^2 (mod p).
     */
    function isOnCurve(
        Curve memory ec,
        APoint memory aPoint_
    ) internal pure returns (bool result_) {
        return _isOnCurve(aPoint_.x, aPoint_.y, ec.a, ec.d, ec.p);
    }

    /**
     * @notice Checks whether a scalar is in the valid range [0, n).
     * @param ec The curve parameters.
     * @param scalar_ The scalar to test.
     * @return result_ True if scalar < n.
     */
    function isValidScalar(Curve memory ec, uint256 scalar_) internal pure returns (bool result_) {
        return scalar_ < ec.n;
    }

    /**
     * @notice Converts a point from projective to affine coordinates.
     * @param ec The curve parameters.
     * @param pPoint_ The projective point (X, Y, Z).
     * @return aPoint_ The equivalent affine point (x, y).
     */
    function toAffine(
        Curve memory ec,
        PPoint memory pPoint_
    ) internal view returns (APoint memory aPoint_) {
        (aPoint_.x, aPoint_.y) = _affineFromProjective(pPoint_, ec.p);
    }

    /**
     * @notice Converts an affine point to projective coordinates.
     * @param aPoint_ The affine point (x, y).
     * @return pPoint_ The projective representation (x, y, 1).
     */
    function toProjective(APoint memory aPoint_) internal pure returns (PPoint memory pPoint_) {
        return PPoint(aPoint_.x, aPoint_.y, 1);
    }

    /**
     * @notice Checks whether a projective point is the point at infinity.
     * @param pPoint_ The projective point to test.
     * @return result_ True if X == 0 && Y == Z.
     */
    function isProjectiveInfinity(PPoint memory pPoint_) internal pure returns (bool result_) {
        return pPoint_.x == 0 && pPoint_.y == pPoint_.z;
    }

    /**
     * @notice Returns the projective representation of the point at infinity.
     * @return pPoint_ The point at infinity (0, 1, 1).
     */
    function pInfinity() internal pure returns (PPoint memory pPoint_) {
        return PPoint(0, 1, 1);
    }

    /**
     * @notice Compares two projective points for equality in affine coordinates.
     * @param ec The curve parameters.
     * @param pPoint1_ The first projective point.
     * @param pPoint2_ The second projective point.
     * @return result_ True if their affine representations match.
     */
    function pEqual(
        Curve memory ec,
        PPoint memory pPoint1_,
        PPoint memory pPoint2_
    ) internal view returns (bool result_) {
        APoint memory aPoint1_ = toAffine(ec, pPoint1_);
        APoint memory aPoint2_ = toAffine(ec, pPoint2_);

        return aPoint1_.x == aPoint2_.x && aPoint1_.y == aPoint2_.y;
    }

    /**
     * @notice Point multiplication: R = u*P using 4-bit windowed method.
     * @param ec The curve parameters.
     * @param pPoint_ The projective point P.
     * @param scalar_ The scalar u.
     * @return pPoint2_ The projective representation of result point R.
     */
    function pMultShamir(
        Curve memory ec,
        PPoint memory pPoint_,
        uint256 scalar_
    ) internal pure returns (PPoint memory pPoint2_) {
        unchecked {
            PPoint[16] memory pPoints_ = _preComputeProjectivePoints(ec, pPoint_);

            for (uint256 i = 0; i < 64; ++i) {
                pPoint2_ = pDoublePoint(ec, pPoint2_);
                pPoint2_ = pDoublePoint(ec, pPoint2_);
                pPoint2_ = pDoublePoint(ec, pPoint2_);
                pPoint2_ = pDoublePoint(ec, pPoint2_);

                // Read 4 bits of u1 which corresponds to the lookup index in the table.
                uint256 pos_ = scalar_ >> 252;
                scalar_ <<= 4;

                pPoint2_ = pAddPoint(ec, pPoints_[pos_], pPoint2_);
            }
        }
    }

    /**
     * @notice Simultaneous double-scalar multiplication: R = u1*P1 + u2*P2 via Strauss–Shamir.
     * @param ec The curve parameters.
     * @param pPoint1_ The first projective point P1.
     * @param pPoint2_ The second projective point P2.
     * @param scalar1_ The first scalar u1.
     * @param scalar2_ The second scalar u2.
     * @return pPoint3_ The projective representation of result point R.
     */
    function pMultShamir2(
        Curve memory ec,
        PPoint memory pPoint1_,
        PPoint memory pPoint2_,
        uint256 scalar1_,
        uint256 scalar2_
    ) internal pure returns (PPoint memory pPoint3_) {
        unchecked {
            PPoint[16] memory pPoints_ = _preComputeProjectivePoints2(ec, pPoint1_, pPoint2_);

            for (uint256 i = 0; i < 128; ++i) {
                pPoint3_ = pDoublePoint(ec, pPoint3_);
                pPoint3_ = pDoublePoint(ec, pPoint3_);

                // Read 2 bits of u1, and 2 bits of u2. Combining the two gives the lookup index in the table.
                uint256 pos_ = ((scalar1_ >> 252) & 0xc) | ((scalar2_ >> 254) & 0x3);
                scalar1_ <<= 2;
                scalar2_ <<= 2;

                pPoint3_ = pAddPoint(ec, pPoints_[pos_], pPoint3_);
            }
        }
    }

    /**
     * @notice Adds two projective points: R = P1 + P2.
     * @param ec The curve parameters.
     * @param pPoint1_ The first projective point P1.
     * @param pPoint2_ The second projective point P2.
     * @return pPoint3_ The projective representation of result point R.
     */
    function pAddPoint(
        Curve memory ec,
        PPoint memory pPoint1_,
        PPoint memory pPoint2_
    ) internal pure returns (PPoint memory pPoint3_) {
        if (isProjectiveInfinity(pPoint1_)) {
            return PPoint(pPoint2_.x, pPoint2_.y, pPoint2_.z);
        }

        if (isProjectiveInfinity(pPoint2_)) {
            return PPoint(pPoint1_.x, pPoint1_.y, pPoint1_.z);
        }

        return _pAdd(pPoint1_, pPoint2_, ec.p, ec.a, ec.d);
    }

    /**
     * @notice Doubles a projective point: R = 2*P.
     * @param ec The curve parameters.
     * @param pPoint1_ The projective point P to double.
     * @return pPoint2_ The projective representation of result point R.
     */
    function pDoublePoint(
        Curve memory ec,
        PPoint memory pPoint1_
    ) internal pure returns (PPoint memory pPoint2_) {
        if (isProjectiveInfinity(pPoint1_)) {
            return PPoint(pPoint1_.x, pPoint1_.y, pPoint1_.z);
        }

        return _pDouble(pPoint1_, ec.p, ec.a);
    }

    /**
     * @dev Point addition on the projective coordinates
     * Reference: https://hyperelliptic.org/EFD/g1p/auto-twisted-projective.html#addition-add-2008-bbjlp
     */
    function _pAdd(
        PPoint memory pPoint1_,
        PPoint memory pPoint2_,
        uint256 p_,
        uint256 a_,
        uint256 d_
    ) private pure returns (PPoint memory pPoint3_) {
        assembly ("memory-safe") {
            let A_ := mulmod(mload(add(pPoint1_, 0x40)), mload(add(pPoint2_, 0x40)), p_)
            let B_ := mulmod(A_, A_, p_)
            let C_ := mulmod(mload(pPoint1_), mload(pPoint2_), p_)
            let D_ := mulmod(mload(add(pPoint1_, 0x20)), mload(add(pPoint2_, 0x20)), p_)
            let E_ := mulmod(d_, mulmod(C_, D_, p_), p_)
            let F_ := addmod(B_, sub(p_, E_), p_)
            let G_ := addmod(B_, E_, p_)
            let H_ := mulmod(
                addmod(mload(pPoint1_), mload(add(pPoint1_, 0x20)), p_),
                addmod(mload(pPoint2_), mload(add(pPoint2_, 0x20)), p_),
                p_
            )
            let I_ := addmod(addmod(H_, sub(p_, C_), p_), sub(p_, D_), p_)
            let J_ := addmod(D_, sub(p_, mulmod(a_, C_, p_)), p_)

            mstore(pPoint3_, mulmod(F_, mulmod(A_, I_, p_), p_))
            mstore(add(pPoint3_, 0x20), mulmod(G_, mulmod(A_, J_, p_), p_))
            mstore(add(pPoint3_, 0x40), mulmod(F_, G_, p_))
        }
    }

    /**
     * @dev Point doubling on the jacobian coordinates
     * Reference: https://hyperelliptic.org/EFD/g1p/auto-twisted-projective.html#doubling-dbl-2008-bbjlp
     */
    function _pDouble(
        PPoint memory pPoint1_,
        uint256 p_,
        uint256 a_
    ) private pure returns (PPoint memory pPoint2_) {
        assembly ("memory-safe") {
            let A_ := addmod(mload(pPoint1_), mload(add(pPoint1_, 0x20)), p_)
            let B_ := mulmod(mload(pPoint1_), mload(pPoint1_), p_)
            let C_ := mulmod(mload(add(pPoint1_, 0x20)), mload(add(pPoint1_, 0x20)), p_)
            let D_ := mulmod(a_, B_, p_)
            let E_ := addmod(D_, C_, p_)
            let F_ := addmod(
                E_,
                sub(
                    p_,
                    mulmod(
                        2,
                        mulmod(mload(add(pPoint1_, 0x40)), mload(add(pPoint1_, 0x40)), p_),
                        p_
                    )
                ),
                p_
            )

            mstore(
                pPoint2_,
                mulmod(
                    addmod(addmod(mulmod(A_, A_, p_), sub(p_, B_), p_), sub(p_, C_), p_),
                    F_,
                    p_
                )
            )
            mstore(add(pPoint2_, 0x20), mulmod(E_, addmod(D_, sub(p_, C_), p_), p_))
            mstore(add(pPoint2_, 0x40), mulmod(E_, F_, p_))
        }
    }

    /**
     * @dev Internal conversion from projective to affine coordinates.
     */
    function _affineFromProjective(
        PPoint memory pPoint_,
        uint256 p_
    ) private view returns (uint256 ax_, uint256 ay_) {
        if (isProjectiveInfinity(pPoint_)) {
            return (0, 1);
        }

        uint256 zInverse_ = Math.invModPrime(pPoint_.z, p_);

        assembly ("memory-safe") {
            ax_ := mulmod(mload(pPoint_), zInverse_, p_)
            ay_ := mulmod(mload(add(pPoint_, 0x20)), zInverse_, p_)
        }
    }

    /**
     * @dev Internal curve equation check in affine coordinates.
     */
    function _isOnCurve(
        uint256 ax_,
        uint256 ay_,
        uint256 a_,
        uint256 d_,
        uint256 p_
    ) private pure returns (bool result_) {
        assembly ("memory-safe") {
            let xx_ := mulmod(ax_, ax_, p_)
            let yy_ := mulmod(ay_, ay_, p_)

            let axx_ := mulmod(a_, xx_, p_)

            let lhs_ := addmod(axx_, yy_, p_)

            let xxyy_ := mulmod(xx_, yy_, p_)
            let dxxyy_ := mulmod(d_, xxyy_, p_)

            let rhs_ := addmod(1, dxxyy_, p_)

            result_ := and(and(lt(ax_, p_), lt(ay_, p_)), eq(lhs_, rhs_))
        }
    }

    /**
     * @dev Precomputes 4-bit window lookup table for one point (Shamir's trick)
     */
    function _preComputeProjectivePoints(
        Curve memory ec,
        PPoint memory pPoint_
    ) private pure returns (PPoint[16] memory pPoints_) {
        pPoints_[0x00] = pInfinity();
        pPoints_[0x01] = pPoint_;
        pPoints_[0x02] = pDoublePoint(ec, pPoints_[0x01]);
        pPoints_[0x04] = pDoublePoint(ec, pPoints_[0x02]);
        pPoints_[0x08] = pDoublePoint(ec, pPoints_[0x04]);
        pPoints_[0x03] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x02]);
        pPoints_[0x06] = pDoublePoint(ec, pPoints_[0x03]);
        pPoints_[0x0c] = pDoublePoint(ec, pPoints_[0x06]);
        pPoints_[0x05] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x04]);
        pPoints_[0x0a] = pDoublePoint(ec, pPoints_[0x05]);
        pPoints_[0x07] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x06]);
        pPoints_[0x0e] = pDoublePoint(ec, pPoints_[0x07]);
        pPoints_[0x09] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x08]);
        pPoints_[0x0b] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x0a]);
        pPoints_[0x0d] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x0c]);
        pPoints_[0x0f] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x0e]);
    }

    /**
     * @dev Precomputes 2-bit window lookup table for two points (Shamir's trick)
     */
    function _preComputeProjectivePoints2(
        Curve memory ec,
        PPoint memory pPoint1_,
        PPoint memory pPoint2_
    ) private pure returns (PPoint[16] memory pPoints_) {
        pPoints_[0x00] = pInfinity();
        pPoints_[0x01] = pPoint2_;
        pPoints_[0x04] = pPoint1_;
        pPoints_[0x02] = pDoublePoint(ec, pPoints_[0x01]);
        pPoints_[0x08] = pDoublePoint(ec, pPoints_[0x04]);
        pPoints_[0x03] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x02]);
        pPoints_[0x05] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x04]);
        pPoints_[0x06] = pAddPoint(ec, pPoints_[0x02], pPoints_[0x04]);
        pPoints_[0x07] = pAddPoint(ec, pPoints_[0x03], pPoints_[0x04]);
        pPoints_[0x09] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x08]);
        pPoints_[0x0a] = pAddPoint(ec, pPoints_[0x02], pPoints_[0x08]);
        pPoints_[0x0b] = pAddPoint(ec, pPoints_[0x03], pPoints_[0x08]);
        pPoints_[0x0c] = pAddPoint(ec, pPoints_[0x04], pPoints_[0x08]);
        pPoints_[0x0d] = pAddPoint(ec, pPoints_[0x01], pPoints_[0x0c]);
        pPoints_[0x0e] = pAddPoint(ec, pPoints_[0x02], pPoints_[0x0c]);
        pPoints_[0x0f] = pAddPoint(ec, pPoints_[0x03], pPoints_[0x0c]);
    }
}
