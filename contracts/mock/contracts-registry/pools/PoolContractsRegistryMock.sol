// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ContractsRegistryPoolMock} from "./ContractsRegistryPoolMock.sol";

import {OwnablePoolContractsRegistry} from "../../../contracts-registry/pools/presets/OwnablePoolContractsRegistry.sol";

contract PoolContractsRegistryMock is OwnablePoolContractsRegistry {
    string public constant POOL_1_NAME = "POOL_1";
    string public constant POOL_2_NAME = "POOL_2";

    address internal _poolFactory;

    error CallerNotAFactory(address caller, address factory);

    modifier onlyPoolFactory() {
        if (_poolFactory != msg.sender) revert CallerNotAFactory(msg.sender, _poolFactory);
        _;
    }

    function mockInit() external {
        __PoolContractsRegistry_init();
    }

    function setDependencies(address contractsRegistry_, bytes memory data_) public override {
        super.setDependencies(contractsRegistry_, data_);

        _poolFactory = ContractsRegistryPoolMock(contractsRegistry_).getPoolFactoryContract();
    }

    function addProxyPool(
        string memory name_,
        address poolAddress_
    ) public override onlyPoolFactory {
        _addProxyPool(name_, poolAddress_);
    }
}
