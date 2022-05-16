// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../libs/arrays/ArrayHelper.sol";

contract ArrayHelperMock {
    using ArrayHelper for uint256[];

    function reverse(uint256[] memory arr) external pure returns (uint256[] memory) {
        return arr.reverse();
    }
}
