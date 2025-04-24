// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {BN254} from "../../../libs/crypto/BN254.sol";

contract BN254Mock {
    function pointAdd(
        BN254.G1Affine memory a_,
        BN254.G1Affine memory b_
    ) external view returns (BN254.G1Affine memory r_) {
        return BN254.pointAdd(a_, b_);
    }

    function pointSub(
        BN254.G1Affine memory a_,
        BN254.G1Affine memory b_
    ) external view returns (BN254.G1Affine memory r_) {
        return BN254.pointSub(a_, b_);
    }

    function pointMul(
        BN254.G1Affine memory p_,
        BN254.Scalar memory a_
    ) external view returns (BN254.G1Affine memory r_) {
        return BN254.pointMul(p_, a_);
    }
}
