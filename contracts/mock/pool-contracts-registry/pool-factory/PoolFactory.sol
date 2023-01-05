// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ContractsRegistry2.sol";
import "../PoolContractsRegistry.sol";

import "../../../pool-contracts-registry/pool-factory/AbstractPoolFactory.sol";

contract PoolFactory is AbstractPoolFactory {
    address public poolContractsRegistry;

    function setDependencies(address contractsRegistry) public override {
        super.setDependencies(contractsRegistry);

        poolContractsRegistry = ContractsRegistry2(contractsRegistry)
            .getPoolContractsRegistryContract();
    }

    function deployPool() external {
        string memory poolType = PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME();

        address poolProxy = _deploy(poolContractsRegistry, poolType);
        _register(poolContractsRegistry, poolType, poolProxy);
        _injectDependencies(poolContractsRegistry, poolProxy);
    }

    function deploy2Pool(string calldata salt) external {
        string memory poolType = PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME();

        address poolProxy = _deploy2(poolContractsRegistry, poolType, bytes32(bytes(salt)));
        _register(poolContractsRegistry, poolType, poolProxy);
        _injectDependencies(poolContractsRegistry, poolProxy);
    }

    function predictPoolAddress(string calldata salt) external view returns (address) {
        return
            _predictPoolAddress(
                poolContractsRegistry,
                PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME(),
                bytes32(bytes(salt))
            );
    }
}
