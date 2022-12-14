// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../contracts-registry/AbstractDependant.sol";

import "./ContractsRegistry2.sol";

contract Pool is AbstractDependant {
    address public token;

    function setDependencies(address contractsRegistry) external override dependant {
        token = ContractsRegistry2(contractsRegistry).getTokenContract();
    }
}
