// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {IndexedMerkleTree} from "../../../libs/data-structures/IndexedMerkleTree.sol";

contract IndexedMerkleTreeMock {
    using IndexedMerkleTree for *;

    IndexedMerkleTree.UintIndexedMT internal _uintTree;

    function initializeUintTree() external {
        _uintTree.initialize();
    }

    function addUint(uint256 value_, uint256 lowLeafIndex_) external returns (uint256) {
        return _uintTree.add(value_, lowLeafIndex_);
    }

    function getProof(
        uint256 index_,
        uint256 value_
    ) external view returns (IndexedMerkleTree.Proof memory) {
        return _uintTree.getProof(index_, value_);
    }

    function verifyProof(IndexedMerkleTree.Proof memory proof_) external view returns (bool) {
        return _uintTree.verifyProof(proof_);
    }

    function processProof(IndexedMerkleTree.Proof memory proof_) external pure returns (bytes32) {
        return IndexedMerkleTree.processProof(proof_);
    }

    function getRoot() external view returns (bytes32) {
        return _uintTree.getRoot();
    }

    function getTreeLevels() external view returns (uint256) {
        return _uintTree.getTreeLevels();
    }

    function getLeafData(
        uint256 leafIndex_
    ) external view returns (IndexedMerkleTree.LeafData memory) {
        return _uintTree.getLeafData(leafIndex_);
    }

    function getNodeHash(uint256 index_, uint256 level_) external view returns (bytes32) {
        return _uintTree.getNodeHash(index_, level_);
    }

    function getLeavesCount() external view returns (uint256) {
        return _uintTree.getLeavesCount();
    }

    function getLevelNodesCount(uint256 level_) external view returns (uint256) {
        return _uintTree.getLevelNodesCount(level_);
    }
}
