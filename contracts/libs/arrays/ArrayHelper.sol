// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *  @notice A simple library to reverse common arrays
 */
library ArrayHelper {
    function reverse(uint256[] memory arr) internal pure returns (uint256[] memory reversed) {
        reversed = new uint256[](arr.length);
        uint256 i = arr.length;

        while (i > 0) {
            i--;
            reversed[arr.length - 1 - i] = arr[i];
        }
    }

    function reverse(address[] memory arr) internal pure returns (address[] memory reversed) {
        reversed = new address[](arr.length);
        uint256 i = arr.length;

        while (i > 0) {
            i--;
            reversed[arr.length - 1 - i] = arr[i];
        }
    }

    function asArray(address elem) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = elem;
    }

    function asArray(uint256 elem) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = elem;
    }
}
