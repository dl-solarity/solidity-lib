// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CartesianMerkleTree} from "../../../libs/data-structures/CartesianMerkleTree.sol";

contract CartesianMerkleTreeMock {
    using CartesianMerkleTree for *;

    CartesianMerkleTree.UintCMT internal _uintCMT;
    CartesianMerkleTree.Bytes32CMT internal _bytes32CMT;
    CartesianMerkleTree.AddressCMT internal _addressCMT;

    function insertUint(uint256 key_, uint128 value_) external {
        _uintCMT.insert(key_, value_);
    }

    function removeUint(uint256 key_) external {
        _uintCMT.remove(key_);
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
}
