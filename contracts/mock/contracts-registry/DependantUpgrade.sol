// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Dependant} from "./Dependant.sol";

contract DependantUpgrade is Dependant {
    uint256 public dummyValue;

    function doUpgrade(uint256 value_) external {
        dummyValue = value_;
    }

    function addedFunction() external pure returns (uint256) {
        return 42;
    }
}
