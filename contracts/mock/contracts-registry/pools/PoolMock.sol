// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractDependant} from "../../../contracts-registry/AbstractDependant.sol";

import {ContractsRegistryPoolMock} from "./ContractsRegistryPoolMock.sol";

contract PoolMock is AbstractDependant {
    address public token;

    function setDependencies(address contractsRegistry_, bytes memory) public override dependant {
        token = ContractsRegistryPoolMock(contractsRegistry_).getTokenContract();
    }
}
