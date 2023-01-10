// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ContractsRegistry2.sol";
import "../PoolContractsRegistry.sol";

import "../../../../contracts-registry/pools/pool-factory/AbstractPoolFactory.sol";

contract PoolFactory is AbstractPoolFactory {
    address public poolContractsRegistry;

    function setDependencies(address contractsRegistry_, bytes calldata data_) public override {
        super.setDependencies(contractsRegistry_, data_);

        poolContractsRegistry = ContractsRegistry2(contractsRegistry_)
            .getPoolContractsRegistryContract();
    }

    function deployPool() external {
        string memory poolType_ = PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME();

        address poolProxy_ = _deploy(poolContractsRegistry, poolType_);

        _register(poolContractsRegistry, poolType_, poolProxy_);
        _injectDependencies(poolContractsRegistry, poolProxy_);
    }

    function deploy2Pool(string calldata salt_) external {
        string memory poolType_ = PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME();

        address poolProxy_ = _deploy2(poolContractsRegistry, poolType_, bytes32(bytes(salt_)));

        _register(poolContractsRegistry, poolType_, poolProxy_);
        _injectDependencies(poolContractsRegistry, poolProxy_);
    }

    function predictPoolAddress(string calldata salt_) external view returns (address) {
        return
            _predictPoolAddress(
                poolContractsRegistry,
                PoolContractsRegistry(poolContractsRegistry).POOL_1_NAME(),
                bytes32(bytes(salt_))
            );
    }
}
