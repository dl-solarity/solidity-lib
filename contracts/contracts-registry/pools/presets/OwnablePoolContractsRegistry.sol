// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../AbstractPoolContractsRegistry.sol";

/**
 *  @notice The Ownable preset of PoolContractsRegistry
 */
abstract contract OwnablePoolContractsRegistry is
    AbstractPoolContractsRegistry,
    OwnableUpgradeable
{
    function __OwnablePoolContractsRegistry_init() public initializer {
        __Ownable_init();
        __PoolContractsRegistry_init();
    }

    function setNewImplementations(
        string[] calldata names,
        address[] calldata newImplementations
    ) external onlyOwner {
        _setNewImplementations(names, newImplementations);
    }

    function injectDependenciesToExistingPools(
        string calldata name,
        uint256 offset,
        uint256 limit
    ) external onlyOwner {
        _injectDependenciesToExistingPools(name, offset, limit);
    }
}
