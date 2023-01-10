// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../contracts-registry/AbstractDependant.sol";

import "./ContractsRegistry1.sol";

contract CRDependant is AbstractDependant {
    address public token;

    function setDependencies(
        address contractsRegistry_,
        bytes calldata
    ) external override dependant {
        token = ContractsRegistry1(contractsRegistry_).getTokenContract();
    }
}
