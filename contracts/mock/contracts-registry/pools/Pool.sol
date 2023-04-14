// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractDependant} from "../../../contracts-registry/AbstractDependant.sol";

import {ContractsRegistry2} from "./ContractsRegistry2.sol";

contract Pool is AbstractDependant {
    address public token;

    function setDependencies(
        address contractsRegistry_,
        bytes calldata
    ) external override dependant {
        token = ContractsRegistry2(contractsRegistry_).getTokenContract();
    }
}
