// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractPoolContractsRegistry} from "../AbstractPoolContractsRegistry.sol";
import {MultiOwnable} from "../../../access-control/MultiOwnable.sol";

/**
 * @notice The MultiOwnable preset of PoolContractsRegistry
 */
abstract contract MultiOwnablePoolContractsRegistry is
    AbstractPoolContractsRegistry,
    MultiOwnable
{
    function __MultiOwnablePoolContractsRegistry_init() public initializer {
        __MultiOwnable_init();
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

    function addProxyPool(string calldata name_, address poolAddress_) external virtual;
}
