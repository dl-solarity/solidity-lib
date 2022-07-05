// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CRDependant.sol";

contract CRDependantUpgrade is CRDependant {
    uint256 public dummyValue;

    function doUpgrade(uint256 value) external {
        dummyValue = value;
    }

    function addedFunction() external pure returns (uint256) {
        return 42;
    }
}
