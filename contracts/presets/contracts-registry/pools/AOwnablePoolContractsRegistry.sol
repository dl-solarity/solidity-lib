// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {APoolContractsRegistry} from "../../../contracts-registry/pools/APoolContractsRegistry.sol";

/**
 * @notice The Ownable preset of PoolContractsRegistry
 */
abstract contract AOwnablePoolContractsRegistry is APoolContractsRegistry, OwnableUpgradeable {
    /**
     * @notice The initialization function
     */
    function __AOwnablePoolContractsRegistry_init() public initializer {
        __Ownable_init(msg.sender);
        __APoolContractsRegistry_init();
    }

    /**
     * @notice The function to set new implementation for the registered pools
     * @param names_ the names of registered ProxyBeacons to upgrade
     * @param newImplementations_ the addresses of new implementations to be used
     */
    function setNewImplementations(
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external onlyOwner {
        _setNewImplementations(names_, newImplementations_);
    }

    /**
     * @notice The function to inject dependencies to registered pools (via EIP-6224)
     * @param name_ the name of ProxyBeacon to identify the pools
     * @param offset_ the start index of the pools array
     * @param limit_ the number of pools to inject dependencies to
     */
    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external onlyOwner {
        _injectDependenciesToExistingPools(name_, offset_, limit_);
    }

    /**
     * @notice The function to inject dependencies to registered pools with data (via EIP-6224)
     * @param data_ the data to be passed to `setDependencies()` function
     * @param name_ the name of ProxyBeacon to identify the pools
     * @param offset_ the start index of the pools array
     * @param limit_ the number of pools to inject dependencies to
     */
    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external onlyOwner {
        _injectDependenciesToExistingPoolsWithData(name_, data_, offset_, limit_);
    }
}
