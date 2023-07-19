// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {AbstractPoolContractsRegistry} from "../AbstractPoolContractsRegistry.sol";

/**
 * @notice The Ownable preset of PoolContractsRegistry
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
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external onlyOwner {
        _setNewImplementations(names_, newImplementations_);
    }

    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external onlyOwner {
        _injectDependenciesToExistingPools(name_, offset_, limit_);
    }

    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external onlyOwner {
        _injectDependenciesToExistingPoolsWithData(name_, data_, offset_, limit_);
    }
}
