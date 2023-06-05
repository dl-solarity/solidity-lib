// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IncrementalMerkleTree} from "../../../libs/data-structures/IncrementalMerkleTree.sol";

contract IncrementalMerkleTreeMock {
    using IncrementalMerkleTree for *;

    IncrementalMerkleTree.UintIMT internal _uintTree;
    IncrementalMerkleTree.Bytes32IMT internal _bytes32Tree;
    IncrementalMerkleTree.AddressIMT internal _addressTree;

    function addUint(uint256 element_) external {
        _uintTree.add(element_);
    }

    function addBytes32(bytes32 element_) external {
        _bytes32Tree.add(element_);
    }

    function addAddress(address element_) external {
        _addressTree.add(element_);
    }

    function getUintRoot() external view returns (bytes32) {
        return _uintTree.root();
    }

    function getBytes32Root() external view returns (bytes32) {
        return _bytes32Tree.root();
    }

    function getAddressRoot() external view returns (bytes32) {
        return _addressTree.root();
    }

    function getUintTreeHeight() external view returns (uint256) {
        return _uintTree.height();
    }

    function getBytes32TreeHeight() external view returns (uint256) {
        return _bytes32Tree.height();
    }

    function getAddressTreeHeight() external view returns (uint256) {
        return _addressTree.height();
    }

    function getUintTreeLength() external view returns (uint256) {
        return _uintTree.length();
    }

    function getBytes32TreeLength() external view returns (uint256) {
        return _bytes32Tree.length();
    }

    function getAddressTreeLength() external view returns (uint256) {
        return _addressTree.length();
    }
}
