// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../AbstractContractsRegistry.sol";

/**
 *  @notice The Ownable preset of ContractsRegistry
 */
contract OwnableContractsRegistry is AbstractContractsRegistry, OwnableUpgradeable {
    function __OwnableContractsRegistry_init() public initializer {
        __Ownable_init();
        __ContractsRegistry_init();
    }

    function injectDependencies(string calldata name) external onlyOwner {
        _injectDependencies(name);
    }

    function upgradeContract(string calldata name, address newImplementation) external onlyOwner {
        _upgradeContract(name, newImplementation);
    }

    function upgradeContractAndCall(
        string calldata name,
        address newImplementation,
        bytes calldata data
    ) external onlyOwner {
        _upgradeContractAndCall(name, newImplementation, data);
    }

    function addContract(string calldata name, address contractAddress) external onlyOwner {
        _addContract(name, contractAddress);
    }

    function addProxyContract(string calldata name, address contractAddress) external onlyOwner {
        _addProxyContract(name, contractAddress);
    }

    function justAddProxyContract(
        string calldata name,
        address contractAddress
    ) external onlyOwner {
        _justAddProxyContract(name, contractAddress);
    }

    function removeContract(string calldata name) external onlyOwner {
        _removeContract(name);
    }
}
