// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECEdwards} from "../../../libs/crypto/ECEdwards.sol";

contract ECEdwardsMock {
    using ECEdwards for *;

    ECEdwards.Curve public babyJubJub =
        ECEdwards.Curve({
            a: 168700,
            d: 168696,
            p: 21888242871839275222246405745257275088548364400416034343698204186575808495617,
            n: 2736030358979909402780800718157159386076813972158567259200215660948447373041,
            gx: 5299619240641551281634865583518297030282874472190772894086521144482721001553,
            gy: 16950150798460657717958625567821834550301663161624707787222815936182638968203
        });

    function basepoint() external view returns (ECEdwards.APoint memory) {
        return babyJubJub.basepoint();
    }

    function pBasepoint() external view returns (ECEdwards.PPoint memory) {
        return babyJubJub.pBasepoint();
    }

    function toScalar(uint256 u256_) external view returns (uint256 scalar_) {
        return babyJubJub.toScalar(u256_);
    }

    function isOnCurve(ECEdwards.APoint memory aPoint_) external view returns (bool result_) {
        return babyJubJub.isOnCurve(aPoint_);
    }

    function isValidScalar(uint256 scalar_) external view returns (bool result_) {
        return babyJubJub.isValidScalar(scalar_);
    }

    function isProjectiveInfinity(
        ECEdwards.PPoint memory pPoint_
    ) external view returns (bool result_) {
        return ECEdwards.isProjectiveInfinity(pPoint_);
    }

    function pInfinity() external view returns (ECEdwards.PPoint memory) {
        return ECEdwards.pInfinity();
    }

    function affineInfinity() external view returns (ECEdwards.APoint memory) {
        return babyJubJub.toAffine(ECEdwards.pInfinity());
    }

    function equal(
        ECEdwards.APoint memory p1_,
        ECEdwards.APoint memory p2_
    ) external view returns (bool result_) {
        return babyJubJub.pEqual(p1_.toProjective(), p2_.toProjective());
    }

    function addPoint(
        ECEdwards.APoint memory p1_,
        ECEdwards.APoint memory p2_
    ) external view returns (ECEdwards.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pAddPoint(p1_.toProjective(), p2_.toProjective()));
    }

    function doublePoint(
        ECEdwards.APoint memory p_
    ) external view returns (ECEdwards.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pDoublePoint(p_.toProjective()));
    }

    function multShamir(
        ECEdwards.APoint memory p_,
        uint256 scalar_
    ) external view returns (ECEdwards.APoint memory) {
        return babyJubJub.toAffine(babyJubJub.pMultShamir(p_.toProjective(), scalar_));
    }

    function multShamir2(
        ECEdwards.APoint memory p1_,
        ECEdwards.APoint memory p2_,
        uint256 scalar1_,
        uint256 scalar2_
    ) external view returns (ECEdwards.APoint memory pPoint3_) {
        return
            babyJubJub.toAffine(
                babyJubJub.pMultShamir2(p1_.toProjective(), p2_.toProjective(), scalar1_, scalar2_)
            );
    }
}
