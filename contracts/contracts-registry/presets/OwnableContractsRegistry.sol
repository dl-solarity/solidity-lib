// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {AbstractContractsRegistry} from "../AbstractContractsRegistry.sol";

/**
 * @notice The Ownable preset of ContractsRegistry
 */
contract OwnableContractsRegistry is AbstractContractsRegistry, OwnableUpgradeable {
    function __OwnableContractsRegistry_init() public initializer {
        __Ownable_init();
        __ContractsRegistry_init();
    }

    function injectDependencies(string calldata name_) external onlyOwner {
        _injectDependencies(name_);
    }

    function injectDependenciesWithData(
        string calldata name_,
        bytes calldata data_
    ) external onlyOwner {
        _injectDependenciesWithData(name_, data_);
    }

    function upgradeContract(
        string calldata name_,
        address newImplementation_
    ) external onlyOwner {
        _upgradeContract(name_, newImplementation_);
    }

    function upgradeContractAndCall(
        string calldata name_,
        address newImplementation_,
        bytes calldata data_
    ) external onlyOwner {
        _upgradeContractAndCall(name_, newImplementation_, data_);
    }

    function addContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addContract(name_, contractAddress_);
    }

    function addProxyContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addProxyContract(name_, contractAddress_);
    }

    function justAddProxyContract(
        string calldata name_,
        address contractAddress_
    ) external onlyOwner {
        _justAddProxyContract(name_, contractAddress_);
    }

    function removeContract(string calldata name_) external onlyOwner {
        _removeContract(name_);
    }
}
