// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CartesianMerkleTree} from "../../../libs/data-structures/CartesianMerkleTree.sol";
import {CartesianMerkleTreeV2} from "../../../libs/data-structures/CartesianMerkleTreeV2.sol";

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

contract CartesianMerkleTreeMock {
    using CartesianMerkleTree for *;
    using CartesianMerkleTreeV2 for *;

    CartesianMerkleTree.UintCMT internal _uintCMT;
    CartesianMerkleTreeV2.UintCMT internal _uintCMTV2;

    CartesianMerkleTree.Bytes32CMT internal _bytes32CMT;
    CartesianMerkleTree.AddressCMT internal _addressCMT;

    function setUintPoseidonHasher() external {
        _uintCMT.setHashers(_hash3);
    }

    function setUintPoseidonHasherV2() external {
        _uintCMTV2.setHashers(_hash3);
    }

    function insertUint(uint256 key_) external {
        _uintCMT.insert(key_);
    }

    function insertUintV2(uint256 key_) external {
        _uintCMTV2.insert(key_);
    }

    function removeUint(uint256 key_) external {
        _uintCMT.remove(key_);
    }

    function removeUintV2(uint256 key_) external {
        _uintCMTV2.remove(key_);
    }

    function proof(
        uint256 key_,
        uint32 desiredProofSize_
    ) external view returns (CartesianMerkleTree.Proof memory) {
        return _uintCMT.getProof(key_, desiredProofSize_);
    }

    function getNode(uint64 nodeId_) external view returns (CartesianMerkleTree.Node memory) {
        return _uintCMT.getNode(nodeId_);
    }

    function getNodesCount() external view returns (uint64) {
        return _uintCMT.getNodesCount();
    }

    function getRootNodeIdUint() external view returns (uint256) {
        return _uintCMT.getRootNodeId();
    }

    function getRootUint() external view returns (bytes32) {
        return _uintCMT.getRoot();
    }

    function getNodeV2(uint64 nodeId_) external view returns (CartesianMerkleTreeV2.Node memory) {
        return _uintCMTV2.getNode(nodeId_);
    }

    function getNodesCounV2() external view returns (uint64) {
        return _uintCMTV2.getNodesCount();
    }

    function getRootNodeIdUintV2() external view returns (uint256) {
        return _uintCMTV2.getRootNodeId();
    }

    function getRootUintV2() external view returns (bytes32) {
        return _uintCMTV2.getRoot();
    }

    function _hash3(
        bytes32 element1_,
        bytes32 element2_,
        bytes32 element3_
    ) internal pure returns (bytes32) {
        return
            bytes32(
                PoseidonUnit3L.poseidon(
                    [uint256(element1_), uint256(element2_), uint256(element3_)]
                )
            );
    }
}
