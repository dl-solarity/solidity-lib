// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ContractsRegistry2.sol";

import "../../pool-contracts-registry/AbstractPoolContractsRegistry.sol";

contract PoolContractsRegistry is AbstractPoolContractsRegistry {
    string public constant POOL_1_NAME = "POOL_1";
    string public constant POOL_2_NAME = "POOL_2";

    address internal poolFactory;

    function _onlyPoolFactory() internal view override {
        require(poolFactory == msg.sender, "PoolContractsRegistry: not a factory");
    }

    function setDependencies(address contractsRegistry) public override {
        super.setDependencies(contractsRegistry);

        poolFactory = ContractsRegistry2(contractsRegistry).getPoolFactoryContract();
    }
}
