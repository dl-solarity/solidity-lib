// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractDependant} from "../../../contracts-registry/AbstractDependant.sol";

import {ContractsRegistryPool} from "./ContractsRegistryPool.sol";

contract Pool is AbstractDependant {
    address public token;

    function setDependencies(address contractsRegistry_, bytes memory) public override dependant {
        token = ContractsRegistryPool(contractsRegistry_).getTokenContract();
    }
}
