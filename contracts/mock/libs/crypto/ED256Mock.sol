// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ED256} from "../../../libs/crypto/ED256.sol";

contract ED256Mock {
    using ED256 for *;

    ED256.Curve public babyJubJub =
        ED256.Curve({
            a: 168700,
            d: 168696,
            p: 21888242871839275222246405745257275088548364400416034343698204186575808495617,
            n: 2736030358979909402780800718157159386076813972158567259200215660948447373041,
            gx: 5299619240641551281634865583518297030282874472190772894086521144482721001553,
            gy: 16950150798460657717958625567821834550301663161624707787222815936182638968203
        });

    function basepoint() external view returns (ED256.APoint memory) {
        return babyJubJub.basepoint();
    }

    function pBasepoint() external view returns (ED256.PPoint memory) {
        return babyJubJub.pBasepoint();
    }

    function toScalar(uint256 u256_) external view returns (uint256 scalar_) {
        return babyJubJub.toScalar(u256_);
    }

    function isOnCurve(ED256.APoint memory aPoint_) external view returns (bool result_) {
        return babyJubJub.isOnCurve(aPoint_);
    }

    function isValidScalar(uint256 scalar_) external view returns (bool result_) {
        return babyJubJub.isValidScalar(scalar_);
    }

    function isProjectiveInfinity(
        ED256.PPoint memory pPoint_
    ) external view returns (bool result_) {
        return ED256.isProjectiveInfinity(pPoint_);
    }

    function pInfinity() external view returns (ED256.PPoint memory) {
        return ED256.pInfinity();
    }

    function affineInfinity() external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(ED256.pInfinity());
    }

    function equal(
        ED256.APoint memory p1_,
        ED256.APoint memory p2_
    ) external view returns (bool result_) {
        return babyJubJub.pEqual(p1_.toProjective(), p2_.toProjective());
    }

    function negatePoint(ED256.APoint memory p_) external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pNegatePoint(p_.toProjective()));
    }

    function addPoint(
        ED256.APoint memory p1_,
        ED256.APoint memory p2_
    ) external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pAddPoint(p1_.toProjective(), p2_.toProjective()));
    }

    function subPoint(
        ED256.APoint memory p1_,
        ED256.APoint memory p2_
    ) external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pSubPoint(p1_.toProjective(), p2_.toProjective()));
    }

    function doublePoint(ED256.APoint memory p_) external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pDoublePoint(p_.toProjective()));
    }

    function multShamir(
        ED256.APoint memory p_,
        uint256 scalar_
    ) external view returns (ED256.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pMultShamir(p_.toProjective(), scalar_));
    }

    function multShamir2(
        ED256.APoint memory p1_,
        ED256.APoint memory p2_,
        uint256 scalar1_,
        uint256 scalar2_
    ) external view returns (ED256.APoint memory pPoint3_) {
        return
            babyJubJub.toAffine(
                babyJubJub.pMultShamir2(p1_.toProjective(), p2_.toProjective(), scalar1_, scalar2_)
            );
    }
}
