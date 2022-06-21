// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Pool.sol";

contract PoolUpgrade is Pool {
    function addedFunction() external pure returns (uint256) {
        return 42;
    }
}
