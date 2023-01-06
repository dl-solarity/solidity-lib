// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";

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
     *  @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
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
     *  @notice The internal deploy function that deploys BeaconProxy pointing to the
     *  pool implementation taken from the PoolContractRegistry using the create2 mechanism
     */
    function _deploy2(
        address poolRegistry,
        string memory poolType,
        bytes32 salt
    ) internal returns (address) {
        return
            address(
                new PublicBeaconProxy{salt: salt}(
                    AbstractPoolContractsRegistry(poolRegistry).getProxyBeacon(poolType),
                    ""
                )
            );
    }

    /**
     *  @notice The internal function that registers newly deployed pool in the provided PoolContractRegistry
     */
    function _register(address poolRegistry, string memory poolType, address poolProxy) internal {
        (bool success, ) = poolRegistry.call(
            abi.encodeWithSignature("addProxyPool(string,address)", poolType, poolProxy)
        );

        require(success, "AbstractPoolFactory: failed to register contract");
    }

    /**
     *  @notice The function that injects dependencies to the newly deployed pool and sets
     *  provided PoolContractsRegistry as an injector
     */
    function _injectDependencies(address poolRegistry, address proxy) internal {
        AbstractDependant(proxy).setDependencies(_contractsRegistry);
        AbstractDependant(proxy).setInjector(poolRegistry);
    }

    /**
     *  @notice The view function that computes the address of the pool if deployed via _deploy2
     */
    function _predictPoolAddress(
        address poolRegistry,
        string memory poolType,
        bytes32 salt
    ) internal view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(PublicBeaconProxy).creationCode,
                abi.encode(
                    AbstractPoolContractsRegistry(poolRegistry).getProxyBeacon(poolType),
                    ""
                )
            )
        );

        return Create2.computeAddress(salt, bytecodeHash);
    }
}
