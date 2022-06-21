// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../contracts-registry/AbstractDependant.sol";

import "./ContractsRegistry2.sol";

contract Pool is AbstractDependant {
    address public token;

    function setDependencies(address contractsRegistry) external override dependant {
        ContractsRegistry2 registry = ContractsRegistry2(contractsRegistry);

        token = registry.getTokenContract();
    }
}
