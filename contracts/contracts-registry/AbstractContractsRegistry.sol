// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./AbstractDependant.sol";
import "./ProxyUpgrader.sol";

abstract contract AbstractContractsRegistry is OwnableUpgradeable {
    ProxyUpgrader internal _proxyUpgrader;

    mapping(string => address) private _contracts;
    mapping(address => bool) private _isProxy;

    function __ContractsRegistry_init() external initializer {
        __Ownable_init();

        _proxyUpgrader = new ProxyUpgrader();
    }

    function getContract(string memory name) public view returns (address) {
        address contractAddress = _contracts[name];

        require(contractAddress != address(0), "ContractsRegistry: This mapping doesn't exist");

        return contractAddress;
    }

    function hasContract(string calldata name) external view returns (bool) {
        return _contracts[name] != address(0);
    }

    function injectDependencies(string calldata name) external onlyOwner {
        address contractAddress = _contracts[name];

        require(contractAddress != address(0), "ContractsRegistry: This mapping doesn't exist");

        AbstractDependant dependant = AbstractDependant(contractAddress);
        dependant.setDependencies(address(this));
    }

    function getProxyUpgrader() external view returns (address) {
        require(address(_proxyUpgrader) != address(0), "ContractsRegistry: Bad ProxyUpgrader");

        return address(_proxyUpgrader);
    }

    function getImplementation(string calldata name) external view returns (address) {
        address contractProxy = _contracts[name];

        require(contractProxy != address(0), "ContractsRegistry: This mapping doesn't exist");
        require(_isProxy[contractProxy], "ContractsRegistry: Not a proxy contract");

        return _proxyUpgrader.getImplementation(contractProxy);
    }

    function upgradeContract(string calldata name, address newImplementation) external onlyOwner {
        _upgradeContract(name, newImplementation, bytes(""));
    }

    function upgradeContractAndCall(
        string calldata name,
        address newImplementation,
        bytes memory data
    ) external onlyOwner {
        _upgradeContract(name, newImplementation, data);
    }

    function _upgradeContract(
        string calldata name,
        address newImplementation,
        bytes memory data
    ) internal {
        address contractToUpgrade = _contracts[name];

        require(contractToUpgrade != address(0), "ContractsRegistry: This mapping doesn't exist");
        require(_isProxy[contractToUpgrade], "ContractsRegistry: Not a proxy contract");

        _proxyUpgrader.upgrade(contractToUpgrade, newImplementation, data);
    }

    function addContract(string calldata name, address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
    }

    function addProxyContract(string calldata name, address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            contractAddress,
            address(_proxyUpgrader),
            ""
        );

        _contracts[name] = address(proxy);
        _isProxy[address(proxy)] = true;
    }

    function justAddProxyContract(string calldata name, address contractAddress)
        external
        onlyOwner
    {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
        _isProxy[contractAddress] = true;
    }

    function removeContract(string calldata name) external onlyOwner {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        delete _isProxy[_contracts[name]];
        delete _contracts[name];
    }
}
