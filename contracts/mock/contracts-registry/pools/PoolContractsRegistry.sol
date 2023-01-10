// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ContractsRegistry2.sol";

import "../../../contracts-registry/pools/presets/OwnablePoolContractsRegistry.sol";

contract PoolContractsRegistry is OwnablePoolContractsRegistry {
    string public constant POOL_1_NAME = "POOL_1";
    string public constant POOL_2_NAME = "POOL_2";

    address internal poolFactory;

    modifier onlyPoolFactory() {
        require(poolFactory == msg.sender, "PoolContractsRegistry: not a factory");
        _;
    }

    function mockInit() external {
        __PoolContractsRegistry_init();
    }

    function setDependencies(address contractsRegistry, bytes calldata data) public override {
        super.setDependencies(contractsRegistry, data);

        poolFactory = ContractsRegistry2(contractsRegistry).getPoolFactoryContract();
    }

    function addProxyPool(string calldata name, address poolAddress) external onlyPoolFactory {
        _addProxyPool(name, poolAddress);
    }
}
