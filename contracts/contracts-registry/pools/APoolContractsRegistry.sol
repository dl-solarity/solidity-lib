// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Paginator} from "../../libs/arrays/Paginator.sol";

import {ADependant} from "../../contracts-registry/ADependant.sol";

/**
 * @notice The PoolContractsRegistry module
 *
 * This contract can be used as a pool registry that keeps track of deployed pools by the system.
 * One can integrate factories to deploy and register pools or add them manually otherwise.
 *
 * The registry uses BeaconProxy pattern to provide upgradeability and EIP-6224 pattern to provide dependency
 * injection mechanism into the pools.
 *
 * The PoolContractsRegistry contract operates by managing ProxyBeacons that point to pools' implementations.
 * The factory contract would deploy BeaconProxies that point to these ProxyBeacons, allowing simple and cheap
 * upgradeability mechanics.
 */
abstract contract APoolContractsRegistry is Initializable, ADependant {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;
    using Math for uint256;

    struct APoolContractsRegistryStorage {
        address contractsRegistry;
        mapping(string name => UpgradeableBeacon beacon) beacons;
        mapping(string name => EnumerableSet.AddressSet pools) pools;
    }

    // bytes32(uint256(keccak256("solarity.contract.APoolContractsRegistry")) - 1)
    bytes32 private constant A_POOL_CONTRACTS_REGISTRY_STORAGE =
        0x8d5dd0f70e3c83ece432cedb954444f19062d979f9fc6b474d5ea33604196f67;

    error NoMappingExists(string poolName);
    error NoPoolsToInject(string poolName);
    error ProxyDoesNotExist(string poolName);

    /**
     * @notice The proxy initializer function
     */
    function __APoolContractsRegistry_init() internal onlyInitializing {}

    /**
     * @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     * @param contractsRegistry_ the dependency registry
     */
    function setDependencies(
        address contractsRegistry_,
        bytes memory
    ) public virtual override dependant {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        $.contractsRegistry = contractsRegistry_;
    }

    /**
     * @notice The function to add new pools into the registry. Gets called from APoolFactory
     *
     * Proper only factory access control must be added in descending contracts + `_addProxyPool()` should be called inside.
     *
     * @param name_ the pool's associated name
     * @param poolAddress_ the proxy address of the pool
     */
    function addProxyPool(string memory name_, address poolAddress_) public virtual;

    /**
     * @notice The function to get implementation of the specific pools
     * @param name_ the name of the pools
     * @return address_ the implementation these pools point to
     */
    function getImplementation(string memory name_) public view returns (address) {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        if (address($.beacons[name_]) == address(0)) revert NoMappingExists(name_);

        return $.beacons[name_].implementation();
    }

    /**
     * @notice The function to get the BeaconProxy of the specific pools (mostly needed in the factories)
     * @param name_ the name of the pools
     * @return address the BeaconProxy address
     */
    function getProxyBeacon(string memory name_) public view returns (address) {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        address beacon_ = address($.beacons[name_]);

        if (beacon_ == address(0)) revert ProxyDoesNotExist(name_);

        return beacon_;
    }

    /**
     * @notice The function to check if the address is a pool
     * @param name_ the associated pools name
     * @param pool_ the address to check
     * @return true if pool_ is whithing the registry
     */
    function isPool(string memory name_, address pool_) public view returns (bool) {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        return $.pools[name_].contains(pool_);
    }

    /**
     * @notice The function to count pools by specified name
     * @param name_ the associated pools name
     * @return the number of pools with this name
     */
    function countPools(string memory name_) public view returns (uint256) {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        return $.pools[name_].length();
    }

    /**
     * @dev Returns the address of the contracts registry
     */
    function getContractsRegistry() public view returns (address) {
        return _getAPoolContractsRegistryStorage().contractsRegistry;
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
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        return $.pools[name_].part(offset_, limit_);
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
    ) internal virtual {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        for (uint256 i = 0; i < names_.length; i++) {
            if (address($.beacons[names_[i]]) == address(0)) {
                $.beacons[names_[i]] = UpgradeableBeacon(
                    _deployProxyBeacon(newImplementations_[i])
                );
            }

            if ($.beacons[names_[i]].implementation() != newImplementations_[i]) {
                $.beacons[names_[i]].upgradeTo(newImplementations_[i]);
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
    ) internal virtual {
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
    ) internal virtual {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        EnumerableSet.AddressSet storage _namedPools = $.pools[name_];

        uint256 to_ = (offset_ + limit_).min(_namedPools.length()).max(offset_);

        if (to_ == offset_) revert NoPoolsToInject(name_);

        address contractsRegistry_ = $.contractsRegistry;

        for (uint256 i = offset_; i < to_; i++) {
            ADependant(_namedPools.at(i)).setDependencies(contractsRegistry_, data_);
        }
    }

    /**
     * @notice The function to add new pools into the registry
     * @param name_ the pool's associated name
     * @param poolAddress_ the proxy address of the pool
     */
    function _addProxyPool(string memory name_, address poolAddress_) internal virtual {
        APoolContractsRegistryStorage storage $ = _getAPoolContractsRegistryStorage();

        $.pools[name_].add(poolAddress_);
    }

    /**
     * @notice The utility function to deploy a Proxy Beacon contract to be used within the registry
     * @return the address of a Proxy Beacon
     */
    function _deployProxyBeacon(address implementation_) internal virtual returns (address) {
        return address(new UpgradeableBeacon(implementation_, address(this)));
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getAPoolContractsRegistryStorage()
        private
        pure
        returns (APoolContractsRegistryStorage storage $)
    {
        assembly {
            $.slot := A_POOL_CONTRACTS_REGISTRY_STORAGE
        }
    }
}
