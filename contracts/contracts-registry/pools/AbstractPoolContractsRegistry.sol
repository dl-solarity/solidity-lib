// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Paginator} from "../../libs/arrays/Paginator.sol";

import {AbstractDependant} from "../../contracts-registry/AbstractDependant.sol";

import {ProxyBeacon} from "./proxy/ProxyBeacon.sol";

/**
 * @notice The PoolContractsRegistry module
 *
 * This contract can be used as a pool registry that keeps track of deployed pools by the system.
 * One can integrate factories to deploy and register pools or add them manually
 *
 * The registry uses BeaconProxy pattern to provide upgradeability and Dependant pattern to provide dependency
 * injection mechanism into the pools. This module should be used together with the ContractsRegistry module.
 *
 * The users of this module have to override `_onlyPoolFactory()` method and revert in case a wrong msg.sender is
 * trying to add pools into the registry.
 *
 * The contract is ment to be used behind a proxy itself.
 */
abstract contract AbstractPoolContractsRegistry is Initializable, AbstractDependant {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;
    using Math for uint256;

    address internal _contractsRegistry;

    mapping(string => ProxyBeacon) private _beacons;
    mapping(string => EnumerableSet.AddressSet) internal _pools; // name => pool

    /**
     * @notice The proxy initializer function
     */
    function __PoolContractsRegistry_init() internal onlyInitializing {}

    /**
     * @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     * @param contractsRegistry_ the dependency registry
     */
    function setDependencies(
        address contractsRegistry_,
        bytes calldata
    ) public virtual override dependant {
        _contractsRegistry = contractsRegistry_;
    }

    /**
     * @notice The function to get implementation of the specific pools
     * @param name_ the name of the pools
     * @return address_ the implementation these pools point to
     */
    function getImplementation(string memory name_) public view returns (address) {
        require(
            address(_beacons[name_]) != address(0),
            "PoolContractsRegistry: this mapping doesn't exist"
        );

        return _beacons[name_].implementation();
    }

    /**
     * @notice The function to get the BeaconProxy of the specific pools (mostly needed in the factories)
     * @param name_ the name of the pools
     * @return address the BeaconProxy address
     */
    function getProxyBeacon(string memory name_) public view returns (address) {
        address beacon_ = address(_beacons[name_]);

        require(beacon_ != address(0), "PoolContractsRegistry: bad ProxyBeacon");

        return beacon_;
    }

    /**
     * @notice The function to count pools by specified name
     * @param name_ the associated pools name
     * @return the number of pools with this name
     */
    function countPools(string memory name_) public view returns (uint256) {
        return _pools[name_].length();
    }

    /**
     * @notice The paginated function to list pools by their name (call `countPools()` to account for pagination)
     * @param name_ the associated pools name
     * @param offset_ the starting index in the pools array
     * @param limit_ the number of pools
     * @return pools_ the array of pools proxies
     */
    function listPools(
        string memory name_,
        uint256 offset_,
        uint256 limit_
    ) public view returns (address[] memory pools_) {
        return _pools[name_].part(offset_, limit_);
    }

    /**
     * @notice The function that sets pools' implementations. Deploys ProxyBeacons on the first set.
     * This function is also used to upgrade pools
     * @param names_ the names that are associated with the pools implementations
     * @param newImplementations_ the new implementations of the pools (ProxyBeacons will point to these)
     */
    function _setNewImplementations(
        string[] memory names_,
        address[] memory newImplementations_
    ) internal {
        for (uint256 i = 0; i < names_.length; i++) {
            if (address(_beacons[names_[i]]) == address(0)) {
                _beacons[names_[i]] = new ProxyBeacon();
            }

            if (_beacons[names_[i]].implementation() != newImplementations_[i]) {
                _beacons[names_[i]].upgrade(newImplementations_[i]);
            }
        }
    }

    /**
     * @notice The paginated function that injects new dependencies to the pools
     * @param name_ the pools name that will be injected
     * @param offset_ the starting index in the pools array
     * @param limit_ the number of pools
     */
    function _injectDependenciesToExistingPools(
        string memory name_,
        uint256 offset_,
        uint256 limit_
    ) internal {
        _injectDependenciesToExistingPoolsWithData(name_, bytes(""), offset_, limit_);
    }

    /**
     * @notice The paginated function that injects new dependencies to the pools with the data
     * @param name_ the pools name that will be injected
     * @param data_ the extra context data
     * @param offset_ the starting index in the pools array
     * @param limit_ the number of pools
     */
    function _injectDependenciesToExistingPoolsWithData(
        string memory name_,
        bytes memory data_,
        uint256 offset_,
        uint256 limit_
    ) internal {
        EnumerableSet.AddressSet storage _namedPools = _pools[name_];

        uint256 to_ = (offset_ + limit_).min(_namedPools.length()).max(offset_);

        require(to_ != offset_, "PoolContractsRegistry: no pools to inject");

        address contractsRegistry_ = _contractsRegistry;

        for (uint256 i = offset_; i < to_; i++) {
            AbstractDependant(_namedPools.at(i)).setDependencies(contractsRegistry_, data_);
        }
    }

    /**
     * @notice The function to add new pools into the registry
     * @param name_ the pool's associated name
     * @param poolAddress_ the proxy address of the pool
     */
    function _addProxyPool(string memory name_, address poolAddress_) internal {
        _pools[name_].add(poolAddress_);
    }
}
