// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AvlTree} from "../../../libs/data-structures/AvlTree.sol";

contract AvlTreeMock {
    using AvlTree for *;

    struct customStruct {
        uint256 valueUint;
        bool valueBool;
        string valueString;
    }

    AvlTree.UintAVL internal _uintTree;
    AvlTree.Bytes32AVL internal _bytes32Tree;
    AvlTree.AddressAVL internal _addressTree;

    function setUintDescComparator() external {
        _uintTree.setComparator(_descComparator);
    }

    function setUintValueComparatorUint() external {
        _uintTree.setComparator(_valueComparatorUint);
    }

    function setUintValueComparatorString() external {
        _uintTree.setComparator(_valueComparatorString);
    }

    function setUintValueComparatorStruct() external {
        _uintTree.setComparator(_structComparator);
    }

    function setBytes32DescComparator() external {
        _bytes32Tree.setComparator(_descComparator);
    }

    function setUintValueComparatorAddress() external {
        _addressTree.setComparator(_valueComparatorUint);
    }

    function setAddressDescComparator() external {
        _addressTree.setComparator(_descComparator);
    }

    function insertUintToUint(uint256 key_, uint256 value_) external {
        _uintTree.insert(key_, abi.encode(value_));
    }

    function insertAddressToUint(uint256 key_, address value_) external {
        _uintTree.insert(key_, abi.encode(value_));
    }

    function insertStringToUint(uint256 key_, string calldata value_) external {
        _uintTree.insert(key_, abi.encode(value_));
    }

    function insertStructToUint(uint256 key_, bytes calldata structBytes_) external {
        _uintTree.insert(key_, structBytes_);
    }

    function insertUintToBytes32(bytes32 key_, uint256 value_) external {
        _bytes32Tree.insert(key_, abi.encode(value_));
    }

    function insertUintToAddress(address key_, uint256 value_) external {
        _addressTree.insert(key_, abi.encode(value_));
    }

    function removeUint(uint256 key_) external {
        _uintTree.remove(key_);
    }

    function removeBytes32(bytes32 key_) external {
        _bytes32Tree.remove(key_);
    }

    function removeAddress(address key_) external {
        _addressTree.remove(key_);
    }

    function searchUint(uint256 key_) external view returns (bool) {
        return _uintTree.search(key_);
    }

    function searchBytes32(bytes32 key_) external view returns (bool) {
        return _bytes32Tree.search(key_);
    }

    function searchAddress(address key_) external view returns (bool) {
        return _addressTree.search(key_);
    }

    function getUintValueUint(uint256 key_) external view returns (uint256) {
        return abi.decode(_uintTree.getValue(key_), (uint256));
    }

    function getAddressValueUint(uint256 key_) external view returns (address) {
        return abi.decode(_uintTree.getValue(key_), (address));
    }

    function getStringValueUint(uint256 key_) external view returns (string memory) {
        return abi.decode(_uintTree.getValue(key_), (string));
    }

    function getUintValueBytes32(bytes32 key_) external view returns (uint256) {
        return abi.decode(_bytes32Tree.getValue(key_), (uint256));
    }

    function getUintValueAddress(address key_) external view returns (uint256) {
        return abi.decode(_addressTree.getValue(key_), (uint256));
    }

    function getMinUint() external view returns (uint256) {
        return _uintTree.getMin();
    }

    function getMinBytes32() external view returns (bytes32) {
        return _bytes32Tree.getMin();
    }

    function getMinAddress() external view returns (address) {
        return _addressTree.getMin();
    }

    function getMaxUint() external view returns (uint256) {
        return _uintTree.getMax();
    }

    function getMaxBytes32() external view returns (bytes32) {
        return _bytes32Tree.getMax();
    }

    function getMaxAddress() external view returns (address) {
        return _addressTree.getMax();
    }

    function rootUint() external view returns (uint256) {
        return _uintTree.root();
    }

    function rootBytes32() external view returns (bytes32) {
        return _bytes32Tree.root();
    }

    function rootAddress() external view returns (address) {
        return _addressTree.root();
    }

    function treeSizeUint() external view returns (uint256) {
        return _uintTree.treeSize();
    }

    function treeSizeBytes32() external view returns (uint256) {
        return _bytes32Tree.treeSize();
    }

    function treeSizeAddress() external view returns (uint256) {
        return _addressTree.treeSize();
    }

    function inOrderTraversalUint() external view returns (uint256[] memory) {
        return _uintTree.inOrderTraversal();
    }

    function inOrderTraversalBytes32() external view returns (bytes32[] memory) {
        return _bytes32Tree.inOrderTraversal();
    }

    function inOrderTraversalAddress() external view returns (address[] memory) {
        return _addressTree.inOrderTraversal();
    }

    function preOrderTraversalUint() external view returns (uint256[] memory) {
        return _uintTree.preOrderTraversal();
    }

    function preOrderTraversalBytes32() external view returns (bytes32[] memory) {
        return _bytes32Tree.preOrderTraversal();
    }

    function preOrderTraversalAddress() external view returns (address[] memory) {
        return _addressTree.preOrderTraversal();
    }

    function postOrderTraversalUint() external view returns (uint256[] memory) {
        return _uintTree.postOrderTraversal();
    }

    function postOrderTraversalBytes32() external view returns (bytes32[] memory) {
        return _bytes32Tree.postOrderTraversal();
    }

    function postOrderTraversalAddress() external view returns (address[] memory) {
        return _addressTree.postOrderTraversal();
    }

    function isCustomComparatorSetUint() external view returns (bool) {
        return _uintTree.isCustomComparatorSet();
    }

    function isCustomComparatorSetBytes32() external view returns (bool) {
        return _bytes32Tree.isCustomComparatorSet();
    }

    function isCustomComparatorSetAddress() external view returns (bool) {
        return _addressTree.isCustomComparatorSet();
    }

    function valueToBytesStruct(uint256 value_) external pure returns (bytes memory) {
        return abi.encode(customStruct(value_, true, "test"));
    }

    function _descComparator(
        bytes32 key1_,
        bytes32 key2_,
        bytes memory,
        bytes memory
    ) private pure returns (int8) {
        if (key1_ > key2_) return -1;
        if (key1_ < key2_) return 1;
        return 0;
    }

    function _valueComparatorUint(
        bytes32,
        bytes32,
        bytes memory value1_,
        bytes memory value2_
    ) private pure returns (int8) {
        uint256 aValue = abi.decode(value1_, (uint256));
        uint256 bValue = abi.decode(value2_, (uint256));

        if (aValue < bValue) return -1;
        if (aValue > bValue) return 1;
        return 0;
    }

    function _valueComparatorString(
        bytes32,
        bytes32,
        bytes memory value1_,
        bytes memory value2_
    ) private pure returns (int8) {
        uint256 minLength = value1_.length;
        if (value2_.length < minLength) minLength = value2_.length;

        for (uint i = 0; i < minLength; i++) {
            if (value1_[i] < value2_[i]) return -1;
            else if (value1_[i] > value2_[i]) return 1;
        }

        if (value1_.length < value2_.length) return -1;
        else if (value1_.length > value2_.length) return 1;
        else return 0;
    }

    function _structComparator(
        bytes32,
        bytes32,
        bytes memory value1_,
        bytes memory value2_
    ) private pure returns (int8) {
        customStruct memory aStruct_ = abi.decode(value1_, (customStruct));
        customStruct memory bStruct_ = abi.decode(value2_, (customStruct));

        if (aStruct_.valueUint < bStruct_.valueUint) return -1;
        if (aStruct_.valueUint > bStruct_.valueUint) return 1;
        return 0;
    }
}
