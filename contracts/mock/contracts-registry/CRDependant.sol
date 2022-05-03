// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../contracts-registry/AbstractDependant.sol";

import "./ContractsRegistry.sol";

contract CRDependant is AbstractDependant {
    address public token;

    function setDependencies(address contractsRegistry) external override dependant {
        ContractsRegistry registry = ContractsRegistry(contractsRegistry);

        token = registry.getTokenContract();
    }
}
