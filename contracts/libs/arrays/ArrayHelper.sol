// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice A simple library to work with arrays
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

    function reverse(string[] memory arr) internal pure returns (string[] memory reversed) {
        reversed = new string[](arr.length);
        uint256 i = arr.length;

        while (i > 0) {
            i--;
            reversed[arr.length - 1 - i] = arr[i];
        }
    }

    function insert(
        uint256[] memory to,
        uint256 index,
        uint256[] memory what
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what.length; i++) {
            to[index + i] = what[i];
        }

        return index + what.length;
    }

    function insert(
        address[] memory to,
        uint256 index,
        address[] memory what
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what.length; i++) {
            to[index + i] = what[i];
        }

        return index + what.length;
    }

    function insert(
        string[] memory to,
        uint256 index,
        string[] memory what
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what.length; i++) {
            to[index + i] = what[i];
        }

        return index + what.length;
    }

    function asArray(uint256 elem) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = elem;
    }

    function asArray(address elem) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = elem;
    }

    function asArray(string memory elem) internal pure returns (string[] memory array) {
        array = new string[](1);
        array[0] = elem;
    }
}
