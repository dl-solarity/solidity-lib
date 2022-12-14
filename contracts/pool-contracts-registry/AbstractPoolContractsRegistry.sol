// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../libs/arrays/Paginator.sol";

import "../contracts-registry/AbstractDependant.sol";

import "./ProxyBeacon.sol";

/**
 *  @notice The PoolContractsRegistry module
 *
 *  This contract can be used as a pool registry that keeps track of deployed pools by the system.
 *  One can integrate factories to deploy and register pools or add them manually
 *
 *  The registry uses BeaconProxy pattern to provide upgradeability and Dependant pattern to provide dependency
 *  injection mechanism into the pools. This module should be used together with the ContractsRegistry module.
 *
 *  The users of this module have to override `_onlyPoolFactory()` method and revert in case a wrong msg.sender is
 *  trying to add pools into the registry.
 *
 *  The contract is ment to be used behind a proxy itself.
 */
abstract contract AbstractPoolContractsRegistry is Initializable, AbstractDependant {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;
    using Math for uint256;

    address internal _contractsRegistry;

    mapping(string => ProxyBeacon) private _beacons;
    mapping(string => EnumerableSet.AddressSet) internal _pools; // name => pool

    /**
     *  @notice The proxy initializer function
     */
    function __PoolContractsRegistry_init() internal onlyInitializing {}

    /**
     *  @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     *  @param contractsRegistry the dependency registry
     */
    function setDependencies(address contractsRegistry) public virtual override dependant {
        _contractsRegistry = contractsRegistry;
    }

    /**
     *  @notice The function to get implementation of the specific pools
     *  @param name the name of the pools
     *  @return address the implementation these pools point to
     */
    function getImplementation(string memory name) public view returns (address) {
        require(
            address(_beacons[name]) != address(0),
            "PoolContractsRegistry: This mapping doesn't exist"
        );

        return _beacons[name].implementation();
    }

    /**
     *  @notice The function to get the BeaconProxy of the specific pools (mostly needed in the factories)
     *  @param name the name of the pools
     *  @return address the BeaconProxy address
     */
    function getProxyBeacon(string memory name) public view returns (address) {
        require(address(_beacons[name]) != address(0), "PoolContractsRegistry: Bad ProxyBeacon");

        return address(_beacons[name]);
    }

    /**
     *  @notice The function to count pools by specified name
     *  @param name the associated pools name
     *  @return the number of pools with this name
     */
    function countPools(string memory name) public view returns (uint256) {
        return _pools[name].length();
    }

    /**
     *  @notice The paginated function to list pools by their name (call `countPools()` to account for pagination)
     *  @param name the associated pools name
     *  @param offset the starting index in the pools array
     *  @param limit the number of pools
     *  @return pools the array of pools proxies
     */
    function listPools(
        string memory name,
        uint256 offset,
        uint256 limit
    ) public view returns (address[] memory pools) {
        return _pools[name].part(offset, limit);
    }

    /**
     *  @notice The function that sets pools' implementations. Deploys ProxyBeacons on the first set.
     *  This function is also used to upgrade pools
     *  @param names the names that are associated with the pools implementations
     *  @param newImplementations the new implementations of the pools (ProxyBeacons will point to these)
     */
    function _setNewImplementations(
        string[] memory names,
        address[] memory newImplementations
    ) internal {
        for (uint256 i = 0; i < names.length; i++) {
            if (address(_beacons[names[i]]) == address(0)) {
                _beacons[names[i]] = new ProxyBeacon();
            }

            if (_beacons[names[i]].implementation() != newImplementations[i]) {
                _beacons[names[i]].upgrade(newImplementations[i]);
            }
        }
    }

    /**
     *  @notice The paginated function that injects new dependencies to the pools. Can be used when the dependant contract
     *  gets fully replaced to update the pools' dependencies
     *  @param name the pools name that will be injected
     *  @param offset the starting index in the pools array
     *  @param limit the number of pools
     */
    function _injectDependenciesToExistingPools(
        string memory name,
        uint256 offset,
        uint256 limit
    ) internal {
        EnumerableSet.AddressSet storage pools = _pools[name];

        uint256 to = (offset + limit).min(pools.length()).max(offset);

        require(to != offset, "PoolContractsRegistry: No pools to inject");

        address contractsRegistry = _contractsRegistry;

        for (uint256 i = offset; i < to; i++) {
            AbstractDependant(pools.at(i)).setDependencies(contractsRegistry);
        }
    }

    /**
     *  @notice The function to add new pools into the registry
     *  @param name the pool's associated name
     *  @param poolAddress the proxy address of the pool
     */
    function _addProxyPool(string memory name, address poolAddress) internal {
        _pools[name].add(poolAddress);
    }
}
