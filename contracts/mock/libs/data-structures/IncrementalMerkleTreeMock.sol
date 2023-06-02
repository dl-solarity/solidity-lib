// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IncrementalMerkleTree} from "../../../libs/data-structures/IncrementalMerkleTree.sol";

contract IncrementalMerkleTreeMock {
    using IncrementalMerkleTree for IncrementalMerkleTree.UintIMT;
    using IncrementalMerkleTree for IncrementalMerkleTree.Bytes32IMT;
    using IncrementalMerkleTree for IncrementalMerkleTree.AddressIMT;

    IncrementalMerkleTree.UintIMT internal uintTree;
    IncrementalMerkleTree.Bytes32IMT internal bytes32Tree;
    IncrementalMerkleTree.AddressIMT internal addressTree;

    function addUint(uint256 element_) external {
        uintTree.addUint(element_);
    }

    function addBytes32(bytes32 element_) external {
        bytes32Tree.addBytes32(element_);
    }

    function addAddress(address element_) external {
        addressTree.addAddress(element_);
    }

    function getUintRoot() external view returns (bytes32) {
        return uintTree.getRoot();
    }

    function getBytes32Root() external view returns (bytes32) {
        return bytes32Tree.getRoot();
    }

    function getAddressRoot() external view returns (bytes32) {
        return addressTree.getRoot();
    }

    function getUintTreeHeight() external view returns (uint256) {
        return uintTree.getTreeHeight();
    }

    function getBytes32TreeHeight() external view returns (uint256) {
        return bytes32Tree.getTreeHeight();
    }

    function getAddressTreeHeight() external view returns (uint256) {
        return addressTree.getTreeHeight();
    }
}
