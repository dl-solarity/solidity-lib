// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {IndexedMerkleTree} from "../../../libs/data-structures/IndexedMerkleTree.sol";

contract IndexedMerkleTreeMock {
    using IndexedMerkleTree for *;

    IndexedMerkleTree.UintIndexedMT internal _uintTree;
    IndexedMerkleTree.Bytes32IndexedMT internal _bytes32Tree;
    IndexedMerkleTree.AddressIndexedMT internal _addressTree;

    function initializeUintTree() external {
        _uintTree.initialize();
    }

    function initializeBytes32Tree() external {
        _bytes32Tree.initialize();
    }

    function initializeAddressTree() external {
        _addressTree.initialize();
    }

    function addUint(uint256 value_, uint256 lowLeafIndex_) external returns (uint256) {
        return _uintTree.add(value_, lowLeafIndex_);
    }

    function addBytes32(bytes32 value_, uint256 lowLeafIndex_) external returns (uint256) {
        return _bytes32Tree.add(value_, lowLeafIndex_);
    }

    function addAddress(address value_, uint256 lowLeafIndex_) external returns (uint256) {
        return _addressTree.add(value_, lowLeafIndex_);
    }

    function getProofUint(
        uint256 index_,
        uint256 value_
    ) external view returns (IndexedMerkleTree.Proof memory) {
        return _uintTree.getProof(index_, value_);
    }

    function getProofBytes32(
        uint256 index_,
        bytes32 value_
    ) external view returns (IndexedMerkleTree.Proof memory) {
        return _bytes32Tree.getProof(index_, value_);
    }

    function getProofAddress(
        uint256 index_,
        address value_
    ) external view returns (IndexedMerkleTree.Proof memory) {
        return _addressTree.getProof(index_, value_);
    }

    function verifyProofUint(IndexedMerkleTree.Proof memory proof_) external view returns (bool) {
        return _uintTree.verifyProof(proof_);
    }

    function verifyProofBytes32(
        IndexedMerkleTree.Proof memory proof_
    ) external view returns (bool) {
        return _bytes32Tree.verifyProof(proof_);
    }

    function verifyProofAddress(
        IndexedMerkleTree.Proof memory proof_
    ) external view returns (bool) {
        return _addressTree.verifyProof(proof_);
    }

    function processProof(IndexedMerkleTree.Proof memory proof_) external pure returns (bytes32) {
        return IndexedMerkleTree.processProof(proof_);
    }

    function getRootUint() external view returns (bytes32) {
        return _uintTree.getRoot();
    }

    function getRootBytes32() external view returns (bytes32) {
        return _bytes32Tree.getRoot();
    }

    function getRootAddress() external view returns (bytes32) {
        return _addressTree.getRoot();
    }

    function getTreeLevelsUint() external view returns (uint256) {
        return _uintTree.getTreeLevels();
    }

    function getTreeLevelsBytes32() external view returns (uint256) {
        return _bytes32Tree.getTreeLevels();
    }

    function getTreeLevelsAddress() external view returns (uint256) {
        return _addressTree.getTreeLevels();
    }

    function getLeafDataUint(
        uint256 leafIndex_
    ) external view returns (IndexedMerkleTree.LeafData memory) {
        return _uintTree.getLeafData(leafIndex_);
    }

    function getLeafDataBytes32(
        uint256 leafIndex_
    ) external view returns (IndexedMerkleTree.LeafData memory) {
        return _bytes32Tree.getLeafData(leafIndex_);
    }

    function getLeafDataAddress(
        uint256 leafIndex_
    ) external view returns (IndexedMerkleTree.LeafData memory) {
        return _addressTree.getLeafData(leafIndex_);
    }

    function getNodeHashUint(uint256 index_, uint256 level_) external view returns (bytes32) {
        return _uintTree.getNodeHash(index_, level_);
    }

    function getNodeHashBytes32(uint256 index_, uint256 level_) external view returns (bytes32) {
        return _bytes32Tree.getNodeHash(index_, level_);
    }

    function getNodeHashAddress(uint256 index_, uint256 level_) external view returns (bytes32) {
        return _addressTree.getNodeHash(index_, level_);
    }

    function getLeavesCountUint() external view returns (uint256) {
        return _uintTree.getLeavesCount();
    }

    function getLeavesCountBytes32() external view returns (uint256) {
        return _bytes32Tree.getLeavesCount();
    }

    function getLeavesCountAddress() external view returns (uint256) {
        return _addressTree.getLeavesCount();
    }

    function getLevelNodesCountUint(uint256 level_) external view returns (uint256) {
        return _uintTree.getLevelNodesCount(level_);
    }

    function getLevelNodesCountBytes32(uint256 level_) external view returns (uint256) {
        return _bytes32Tree.getLevelNodesCount(level_);
    }

    function getLevelNodesCountAddress(uint256 level_) external view returns (uint256) {
        return _addressTree.getLevelNodesCount(level_);
    }
}
