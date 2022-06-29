// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *  @notice A simple library that adds functionality when working with arrays.
 */
library ArrayHelper {
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function asArray(uint256 elem_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = elem_;
    }

    function asArray(address elem_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = elem_;
    }
}
