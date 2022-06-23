// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../contracts-registry/AbstractDependant.sol";
import "../AbstractPoolContractsRegistry.sol";

import "./PublicBeaconProxy.sol";

/**
 *  @notice The PoolContractsRegistry module
 *
 *  This is an abstract factory contract that is used in pair with the PoolContractsRegistry contract to
 *  deploy, register and inject pools.
 *
 *  The actual `deploy()` function has to be implemented in the descendants of this contract. The deployment
 *  is made via the BeaconProxy pattern.
 */
abstract contract AbstractPoolFactory is AbstractDependant {
    address internal _contractsRegistry;

    /**
     *  @notice The function that accepts dependencies from the ContractsRegistry, can be overriden
     *  @param contractsRegistry the dependency registry
     */
    function setDependencies(address contractsRegistry) public virtual override dependant {
        _contractsRegistry = contractsRegistry;
    }

    /**
     *  @notice The internal deploy function that deploys BeaconProxy pointing to the
     *  pool implementation taken from the PoolContractRegistry
     */
    function _deploy(address poolRegistry, string memory poolType) internal returns (address) {
        return
            address(
                new PublicBeaconProxy(
                    AbstractPoolContractsRegistry(poolRegistry).getProxyBeacon(poolType),
                    ""
                )
            );
    }

    /**
     *  @notice The internal function that registers newly deployed pool in the provided PoolContractRegistry
     */
    function _register(
        address poolRegistry,
        string memory poolType,
        address poolProxy
    ) internal {
        AbstractPoolContractsRegistry(poolRegistry).addPool(poolType, poolProxy);
    }

    /**
     *  @notice The function that injects dependencies to the newly deployed pool and sets
     *  provided PoolContractsRegistry as an injector
     */
    function _injectDependencies(address poolRegistry, address proxy) internal {
        AbstractDependant(proxy).setDependencies(_contractsRegistry);
        AbstractDependant(proxy).setInjector(poolRegistry);
    }
}
