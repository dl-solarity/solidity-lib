// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {ADependant} from "../../contracts-registry/ADependant.sol";
import {APoolContractsRegistry} from "./APoolContractsRegistry.sol";

/**
 * @notice The PoolContractsRegistry module
 *
 * This is an abstract factory contract that is used in pair with the PoolContractsRegistry contract to
 * deploy, register and inject dependencies to pools. Built via EIP-6224 Contracts Dependencies Registry pattern.
 *
 * The actual `deploy()` function has to be implemented in the descendants of this contract. The deployment
 * is made via the BeaconProxy pattern.
 *
 * Both "create1" and "create2" deployment modes are supported.
 */
abstract contract APoolFactory is ADependant {
    struct APoolFactoryStorage {
        address contractsRegistry;
    }

    // bytes32(uint256(keccak256("solarity.contract.APoolFactory")) - 1)
    bytes32 private constant A_POOL_FACTORY_STORAGE =
        0x1f5518d1b664801322096f1ea43578b6bee500653439ee8a900427e814b7cf43;

    /**
     * @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     * @param contractsRegistry_ the dependency registry
     */
    function setDependencies(
        address contractsRegistry_,
        bytes memory
    ) public virtual override dependant {
        APoolFactoryStorage storage $ = _getAPoolFactoryStorage();

        $.contractsRegistry = contractsRegistry_;
    }

    /**
     * @dev Returns the address of the contracts registry
     */
    function getContractsRegistry() public view returns (address) {
        return _getAPoolFactoryStorage().contractsRegistry;
    }

    /**
     * @notice The internal deploy function that deploys BeaconProxy pointing to the
     * pool implementation taken from the PoolContractRegistry
     */
    function _deploy(
        address poolRegistry_,
        string memory poolType_
    ) internal virtual returns (address) {
        return
            address(
                new BeaconProxy(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            );
    }

    /**
     * @notice The internal deploy function that deploys BeaconProxy pointing to the
     * pool implementation taken from the PoolContractRegistry using the create2 mechanism
     */
    function _deploy2(
        address poolRegistry_,
        string memory poolType_,
        bytes32 salt_
    ) internal virtual returns (address) {
        return
            address(
                new BeaconProxy{salt: salt_}(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            );
    }

    /**
     * @notice The internal function that registers newly deployed pool in the provided PoolContractRegistry
     */
    function _register(
        address poolRegistry_,
        string memory poolType_,
        address poolProxy_
    ) internal virtual {
        APoolContractsRegistry(poolRegistry_).addProxyPool(poolType_, poolProxy_);
    }

    /**
     * @notice The function that injects dependencies to the newly deployed pool and sets
     * provided PoolContractsRegistry as an injector
     */
    function _injectDependencies(address poolRegistry_, address proxy_) internal virtual {
        APoolFactoryStorage storage $ = _getAPoolFactoryStorage();

        ADependant(proxy_).setDependencies($.contractsRegistry, bytes(""));
        ADependant(proxy_).setInjector(poolRegistry_);
    }

    /**
     * @notice The view function that computes the address of the pool if deployed via _deploy2
     */
    function _predictPoolAddress(
        address poolRegistry_,
        string memory poolType_,
        bytes32 salt_
    ) internal view virtual returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(BeaconProxy).creationCode,
                abi.encode(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            )
        );

        return Create2.computeAddress(salt_, bytecodeHash);
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getAPoolFactoryStorage() private pure returns (APoolFactoryStorage storage $) {
        assembly {
            $.slot := A_POOL_FACTORY_STORAGE
        }
    }
}
