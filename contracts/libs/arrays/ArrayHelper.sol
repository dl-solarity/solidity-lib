// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ArrayHelper {
    function reverse(uint256[] memory arr) internal pure returns (uint256[] memory reversed) {
        if (arr.length == 0) return reversed;
        reversed = new uint256[](arr.length);

        uint256 lastIndex = arr.length - 1;
        for (uint256 i; i < arr.length; i++) {
            reversed[i] = arr[lastIndex - i];
        }
    }
}
