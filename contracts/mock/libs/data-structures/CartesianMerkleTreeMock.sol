// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CartesianMerkleTree} from "../../../libs/data-structures/CartesianMerkleTree.sol";

contract CartesianMerkleTreeMock {
    using CartesianMerkleTree for *;

    CartesianMerkleTree.CMT internal _treap;

    function insert(uint256 key_, uint128 value_) external {
        _treap.insert(bytes32(key_), bytes16(value_));
    }

    function remove(uint256 key_) external {
        _treap.remove(bytes32(key_));
    }

    function proof(uint256 key_) external view returns (CartesianMerkleTree.Proof memory) {
        return _treap.proof(bytes32(key_), 10);
    }

    function getNode(uint64 nodeId_) external view returns (CartesianMerkleTree.Node memory) {
        return _treap.nodes[nodeId_];
    }

    function getNodesCount() external view returns (uint64) {
        return _treap.nodesCount;
    }

    function getTreeRootNodeId() external view returns (uint64) {
        return _treap.merkleRootId;
    }
}
