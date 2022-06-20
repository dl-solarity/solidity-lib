// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../libs/arrays/ArrayHelper.sol";

contract ArrayHelperMock {
    using ArrayHelper for *;

    function reverseUint(uint256[] memory arr) external pure returns (uint256[] memory) {
        return arr.reverse();
    }

    function reverseAddress(address[] memory arr) external pure returns (address[] memory) {
        return arr.reverse();
    }
}
