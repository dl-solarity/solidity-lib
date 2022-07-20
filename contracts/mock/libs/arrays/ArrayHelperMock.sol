// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libs/arrays/ArrayHelper.sol";

contract ArrayHelperMock {
    using ArrayHelper for *;

    function reverseUint(uint256[] memory arr) external pure returns (uint256[] memory) {
        return arr.reverse();
    }

    function reverseAddress(address[] memory arr) external pure returns (address[] memory) {
        return arr.reverse();
    }

    function insertUint(
        uint256[] memory to,
        uint256 index,
        uint256[] memory what
    ) external pure returns (uint256, uint256[] memory) {
        return (to.insert(index, what), to);
    }

    function insertAddress(
        address[] memory to,
        uint256 index,
        address[] memory what
    ) external pure returns (uint256, address[] memory) {
        return (to.insert(index, what), to);
    }

    function asArrayUint(uint256 elem) external pure returns (uint256[] memory array) {
        return elem.asArray();
    }

    function asArrayAddress(address elem) external pure returns (address[] memory array) {
        return elem.asArray();
    }
}
