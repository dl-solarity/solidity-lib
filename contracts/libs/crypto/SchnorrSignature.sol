// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {BN254} from "./BN254.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

library SchnorrSignature {
    using MemoryUtils for *;

    function verifySignature(
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool isVerified_) {
        (BN254.G1Affine memory r_, BN254.Scalar memory e_) = parseSignature(signature_);
        BN254.G1Affine memory a_ = parsePubKey(pubKey_);

        BN254.G1Affine memory lhs_ = BN254.basepointMul(e_);

        uint256 challenge_ = uint256(keccak256(abi.encodePacked(r_.x, r_.y, hashedMessage_)));
        BN254.Scalar memory c_ = BN254.scalarFromUint256ModScalar(challenge_);

        BN254.G1Affine memory rhs_ = BN254.pointAdd(r_, BN254.pointMul(a_, c_));

        return BN254.pointEqual(lhs_, rhs_);
    }

    function parseSignature(
        bytes memory signature_
    ) internal pure returns (BN254.G1Affine memory r_, BN254.Scalar memory e_) {
        (uint256 pointX_, uint256 pointY_, uint256 scalar_) = abi.decode(
            signature_,
            (uint256, uint256, uint256)
        );

        r_ = BN254.g1PointFromAffine(pointX_, pointY_);
        e_ = BN254.scalarFromUint256(scalar_);
    }

    function parsePubKey(bytes memory pubKey_) internal pure returns (BN254.G1Affine memory a_) {
        (uint256 pointX_, uint256 pointY_) = abi.decode(pubKey_, (uint256, uint256));

        return BN254.g1PointFromAffine(pointX_, pointY_);
    }
}
