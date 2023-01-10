// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/arrays/ArrayHelper.sol";

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

    function asArrayUint(uint256 elem_) external pure returns (uint256[] memory array_) {
        return elem_.asArray();
    }

    function asArrayAddress(address elem_) external pure returns (address[] memory array_) {
        return elem_.asArray();
    }

    function asArrayString(string memory elem_) external pure returns (string[] memory array_) {
        return elem_.asArray();
    }
}
