// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArrayHelper} from "../../../libs/arrays/ArrayHelper.sol";

contract ArrayHelperMock {
    using ArrayHelper for *;

    function reverseUint(uint256[] memory arr_) external pure returns (uint256[] memory) {
        return arr_.reverse();
    }

    function reverseAddress(address[] memory arr_) external pure returns (address[] memory) {
        return arr_.reverse();
    }

    function reverseString(string[] memory arr_) external pure returns (string[] memory) {
        return arr_.reverse();
    }

    function reverseBytes32(bytes32[] memory arr_) external pure returns (bytes32[] memory) {
        return arr_.reverse();
    }

    function insertUint(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) external pure returns (uint256, uint256[] memory) {
        return (to_.insert(index_, what_), to_);
    }

    function insertAddress(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) external pure returns (uint256, address[] memory) {
        return (to_.insert(index_, what_), to_);
    }

    function insertString(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) external pure returns (uint256, string[] memory) {
        return (to_.insert(index_, what_), to_);
    }

    function insertBytes32(
        bytes32[] memory to_,
        uint256 index_,
        bytes32[] memory what_
    ) external pure returns (uint256, bytes32[] memory) {
        return (to_.insert(index_, what_), to_);
    }

    function cropUint(
        uint256[] memory arr_,
        uint256 newLength_
    ) external pure returns (uint256[] memory) {
        return arr_.crop(newLength_);
    }

    function cropAddress(
        address[] memory arr_,
        uint256 newLength_
    ) external pure returns (address[] memory) {
        return arr_.crop(newLength_);
    }

    function cropBool(
        bool[] memory arr_,
        uint256 newLength_
    ) external pure returns (bool[] memory) {
        return arr_.crop(newLength_);
    }

    function cropString(
        string[] memory arr_,
        uint256 newLength_
    ) external pure returns (string[] memory) {
        return arr_.crop(newLength_);
    }

    function cropBytes(
        bytes32[] memory arr_,
        uint256 newLength_
    ) external pure returns (bytes32[] memory) {
        return arr_.crop(newLength_);
    }

    function countPrefixes(uint256[] memory arr_) external pure returns (uint256[] memory) {
        return arr_.countPrefixes();
    }

    function getRangeSum(
        uint256[] memory arr_,
        uint256 beginIndex_,
        uint256 endIndex_
    ) external pure returns (uint256) {
        return arr_.countPrefixes().getRangeSum(beginIndex_, endIndex_);
    }

    function lowerBound(uint256[] memory arr_, uint256 element_) external pure returns (uint256) {
        return arr_.lowerBound(element_);
    }

    function upperBound(uint256[] memory arr_, uint256 element_) external pure returns (uint256) {
        return arr_.upperBound(element_);
    }
}
