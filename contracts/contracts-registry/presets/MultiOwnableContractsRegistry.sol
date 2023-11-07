// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractContractsRegistry} from "../AbstractContractsRegistry.sol";
import {MultiOwnable} from "../../access-control/MultiOwnable.sol";

/**
 * @notice The MultiOwnable preset of ContractsRegistry
 */
contract MultiOwnableContractsRegistry is AbstractContractsRegistry, MultiOwnable {
    function __MultiOwnableContractsRegistry_init() public initializer {
        __MultiOwnable_init();
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

    function addProxyContractAndCall(
        string calldata name_,
        address contractAddress_,
        bytes calldata data_
    ) external onlyOwner {
        _addProxyContractAndCall(name_, contractAddress_, data_);
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
