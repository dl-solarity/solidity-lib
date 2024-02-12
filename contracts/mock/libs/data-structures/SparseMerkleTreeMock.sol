// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SparseMerkleTree} from "../../../libs/data-structures/SparseMerkleTree.sol";

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

contract SparseMerkleTreeMock {
    using SparseMerkleTree for *;

    SparseMerkleTree.UintSMT internal _uintTree;
    SparseMerkleTree.Bytes32SMT internal _bytes32Tree;
    SparseMerkleTree.AddressSMT internal _addressTree;

    function initializeUintTree(uint64 maxDepth_) external {
        _uintTree.initialize(maxDepth_);
    }

    function initializeBytes32Tree(uint64 maxDepth_) external {
        _bytes32Tree.initialize(maxDepth_);
    }

    function initializeAddressTree(uint64 maxDepth_) external {
        _addressTree.initialize(maxDepth_);
    }

    function setMaxDepthUintTree(uint64 maxDepth_) external {
        _uintTree.setMaxDepth(maxDepth_);
    }

    function setMaxDepthBytes32Tree(uint64 maxDepth_) external {
        _bytes32Tree.setMaxDepth(maxDepth_);
    }

    function setMaxDepthAddressTree(uint64 maxDepth_) external {
        _addressTree.setMaxDepth(maxDepth_);
    }

    function setUintPoseidonHasher() external {
        _uintTree.setHashers(_hash2, _hash3);
    }

    function setBytes32PoseidonHasher() external {
        _bytes32Tree.setHashers(_hash2, _hash3);
    }

    function setAddressPoseidonHasher() external {
        _addressTree.setHashers(_hash2, _hash3);
    }

    function addUint(uint256 key_, uint256 value_) external {
        _uintTree.add(key_, value_);
    }

    function addBytes32(bytes32 key_, bytes32 value_) external {
        _bytes32Tree.add(key_, value_);
    }

    function addAddress(bytes32 key_, address value_) external {
        _addressTree.add(key_, value_);
    }

    function getUintProof(uint256 key_) external view returns (SparseMerkleTree.Proof memory) {
        return _uintTree.getProof(key_);
    }

    function getBytes32Proof(bytes32 key_) external view returns (SparseMerkleTree.Proof memory) {
        return _bytes32Tree.getProof(key_);
    }

    function getAddressProof(bytes32 key_) external view returns (SparseMerkleTree.Proof memory) {
        return _addressTree.getProof(key_);
    }

    function getUintRoot() external view returns (bytes32) {
        return _uintTree.getRoot();
    }

    function getBytes32Root() external view returns (bytes32) {
        return _bytes32Tree.getRoot();
    }

    function getAddressRoot() external view returns (bytes32) {
        return _addressTree.getRoot();
    }

    function getUintNode(uint256 nodeId_) external view returns (SparseMerkleTree.Node memory) {
        return _uintTree.getNode(nodeId_);
    }

    function getBytes32Node(uint256 nodeId_) external view returns (SparseMerkleTree.Node memory) {
        return _bytes32Tree.getNode(nodeId_);
    }

    function getAddressNode(uint256 nodeId_) external view returns (SparseMerkleTree.Node memory) {
        return _addressTree.getNode(nodeId_);
    }

    function getUintNodeByKey(uint256 key_) external view returns (SparseMerkleTree.Node memory) {
        return _uintTree.getNodeByKey(key_);
    }

    function getBytes32NodeByKey(
        bytes32 key_
    ) external view returns (SparseMerkleTree.Node memory) {
        return _bytes32Tree.getNodeByKey(key_);
    }

    function getAddressNodeByKey(
        bytes32 key_
    ) external view returns (SparseMerkleTree.Node memory) {
        return _addressTree.getNodeByKey(key_);
    }

    function getUintMaxDepth() external view returns (uint256) {
        return _uintTree.getMaxDepth();
    }

    function getBytes32MaxDepth() external view returns (uint256) {
        return _bytes32Tree.getMaxDepth();
    }

    function getAddressMaxDepth() external view returns (uint256) {
        return _addressTree.getMaxDepth();
    }

    function getUintNodesCount() external view returns (uint256) {
        return _uintTree.getNodesCount();
    }

    function getBytes32NodesCount() external view returns (uint256) {
        return _bytes32Tree.getNodesCount();
    }

    function getAddressNodesCount() external view returns (uint256) {
        return _addressTree.getNodesCount();
    }

    function isUintCustomHasherSet() external view returns (bool) {
        return _uintTree.isCustomHasherSet();
    }

    function isBytes32CustomHasherSet() external view returns (bool) {
        return _bytes32Tree.isCustomHasherSet();
    }

    function isAddressCustomHasherSet() external view returns (bool) {
        return _addressTree.isCustomHasherSet();
    }

    function _hash2(bytes32 element1_, bytes32 element2_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit2L.poseidon([uint256(element1_), uint256(element2_)]));
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
