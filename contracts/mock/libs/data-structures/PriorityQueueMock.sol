// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/data-structures/PriorityQueue.sol";

contract PriorityQueueMock {
    using PriorityQueue for *;

    PriorityQueue.UintQueue internal _uintQueue;
    PriorityQueue.AddressQueue internal _addressQueue;
    PriorityQueue.Bytes32Queue internal _bytes32Queue;

    // Uint

    function addUint(uint256 value_, uint256 priority_) external {
        _uintQueue.add(value_, priority_);
    }

    function removeUint(uint256 index_) external {
        _uintQueue.remove(index_);
    }

    function removeTopUint() external {
        _uintQueue.removeTop();
    }

    function topUint() external view returns (uint256) {
        return _uintQueue.top();
    }

    function lengthUint() external view returns (uint256) {
        return _uintQueue.length();
    }

    function atUint(uint256 index_) external view returns (uint256, uint256) {
        return _uintQueue.at(index_);
    }

    function valuesUint() external view returns (uint256[] memory, uint256[] memory) {
        return _uintQueue.values();
    }

    // bytes32

    function addBytes32(bytes32 value_, uint256 priority_) external {
        _bytes32Queue.add(value_, priority_);
    }

    function removeBytes32(uint256 index_) external {
        _bytes32Queue.remove(index_);
    }

    function removeTopBytes32() external {
        _bytes32Queue.removeTop();
    }

    function topBytes32() external view returns (bytes32) {
        return _bytes32Queue.top();
    }

    function lengthBytes32() external view returns (uint256) {
        return _bytes32Queue.length();
    }

    function atBytes32(uint256 index_) external view returns (bytes32, uint256) {
        return _bytes32Queue.at(index_);
    }

    function valuesBytes32() external view returns (bytes32[] memory, uint256[] memory) {
        return _bytes32Queue.values();
    }

    // Address

    function addAddress(address value_, uint256 priority_) external {
        _addressQueue.add(value_, priority_);
    }

    function removeAddress(uint256 index_) external {
        _addressQueue.remove(index_);
    }

    function removeTopAddress() external {
        _addressQueue.removeTop();
    }

    function topAddress() external view returns (address) {
        return _addressQueue.top();
    }

    function lengthAddress() external view returns (uint256) {
        return _addressQueue.length();
    }

    function atAddress(uint256 index_) external view returns (address, uint256) {
        return _addressQueue.at(index_);
    }

    function valuesAddress() external view returns (address[] memory, uint256[] memory) {
        return _addressQueue.values();
    }
}
