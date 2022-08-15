// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./AbstractDependant.sol";
import "./ProxyUpgrader.sol";

/**
 *  @notice The ContractsRegistry module
 *
 *  The purpose of this module is to provide an organized registry of the project's smartcontracts
 *  together with the upgradeability and dependency injection mechanisms.
 *
 *  The ContractsRegistry should be used as the highest level smartcontract that is aware of any other
 *  contract present in the system. The contracts that demand other system's contracts would then inherit
 *  special `AbstractDependant` contract and override `setDependencies()` function to enable ContractsRegistry
 *  to inject dependencies into them.
 *
 *  The ContractsRegistry will help with the following usecases:
 *
 *  1) Making the system upgradeable
 *  2) Making the system contracts-interchangeable
 *  3) Simplifying the contracts management and deployment
 *
 *  The ContractsRegistry acts as a Transparent proxy deployer. One can add proxy-compatible implementations to the registry
 *  and deploy proxies to them. Then these proxies can be upgraded easily using the ContractsRegistry.
 *  The ContractsRegistry itself can be deployed behind a proxy as well.
 *
 *  The dependency injection system may come in handy when one wants to substitute a contract `A` with a contract `B`
 *  (for example contract `A` got exploited) without a necessity of redeploying the whole system. One would just add
 *  a new `B` contract to a ContractsRegistry and re-inject all the required dependencies. Dependency injection mechanism
 *  also works with factories.
 *
 *  The management is simplified because all of the contracts are now located in a single place.
 */
abstract contract AbstractContractsRegistry is Initializable {
    ProxyUpgrader private _proxyUpgrader;

    mapping(string => address) private _contracts;
    mapping(address => bool) private _isProxy;

    /**
     *  @notice The proxy initializer function
     */
    function __ContractsRegistry_init() internal onlyInitializing {
        _proxyUpgrader = new ProxyUpgrader();
    }

    /**
     *  @notice The function that returns an associated contract with the name
     *  @param name the name of the contract
     *  @return the address of the contract
     */
    function getContract(string memory name) public view returns (address) {
        address contractAddress = _contracts[name];

        require(contractAddress != address(0), "ContractsRegistry: This mapping doesn't exist");

        return contractAddress;
    }

    /**
     *  @notice The function that check if a contract with a given name has been added
     *  @param name the name of the contract
     *  @return true if the contract is present in the registry
     */
    function hasContract(string memory name) public view returns (bool) {
        return _contracts[name] != address(0);
    }

    /**
     *  @notice The function that returns the admin of the added proxy contracts
     *  @return the proxy admin address
     */
    function getProxyUpgrader() public view returns (address) {
        return address(_proxyUpgrader);
    }

    /**
     *  @notice The function that returns an implementation of the given proxy contract
     *  @param name the name of the contract
     *  @return the implementation address
     */
    function getImplementation(string memory name) public view returns (address) {
        address contractProxy = _contracts[name];

        require(contractProxy != address(0), "ContractsRegistry: This mapping doesn't exist");
        require(_isProxy[contractProxy], "ContractsRegistry: Not a proxy contract");

        return _proxyUpgrader.getImplementation(contractProxy);
    }

    /**
     *  @notice The function that injects the dependencies into the given contract
     *  @param name the name of the contract
     */
    function _injectDependencies(string memory name) internal {
        address contractAddress = _contracts[name];

        require(contractAddress != address(0), "ContractsRegistry: This mapping doesn't exist");

        AbstractDependant dependant = AbstractDependant(contractAddress);
        dependant.setDependencies(address(this));
    }

    /**
     *  @notice The function to upgrade added proxy contract with a new implementation
     *  @param name the name of the proxy contract
     *  @param newImplementation the new implementation the proxy should be upgraded to
     *
     *  It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContract(string memory name, address newImplementation) internal {
        _upgradeContractAndCall(name, newImplementation, bytes(""));
    }

    /**
     *  @notice The function to upgrade added proxy contract with a new implementation, providing data
     *  @param name the name of the proxy contract
     *  @param newImplementation the new implementation the proxy should be upgraded to
     *  @param data the data that the new implementation will be called with. This can be an ABI encoded function call
     *
     *  It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContractAndCall(
        string memory name,
        address newImplementation,
        bytes memory data
    ) internal {
        address contractToUpgrade = _contracts[name];

        require(contractToUpgrade != address(0), "ContractsRegistry: This mapping doesn't exist");
        require(_isProxy[contractToUpgrade], "ContractsRegistry: Not a proxy contract");

        _proxyUpgrader.upgrade(contractToUpgrade, newImplementation, data);
    }

    /**
     *  @notice The function to add pure contracts to the ContractsRegistry. These should either be
     *  the contracts the system does not have direct upgradeability control over, or the contracts that are not upgradeable
     *  @param name the name to associate the contract with
     *  @param contractAddress the address of the contract
     */
    function _addContract(string memory name, address contractAddress) internal {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
    }

    /**
     *  @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     *  contract that the ContractsRegistry should be able to upgrade
     *  @param name the name to associate the contract with
     *  @param contractAddress the address of the implementation
     */
    function _addProxyContract(string memory name, address contractAddress) internal {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        address proxyAddr = address(
            new TransparentUpgradeableProxy(contractAddress, address(_proxyUpgrader), "")
        );

        _contracts[name] = proxyAddr;
        _isProxy[proxyAddr] = true;
    }

    /**
     *  @notice The function to add the already deployed proxy to the ContractsRegistry. This might be used
     *  when the system migrates to a new ContractRegistry. This means that the new ProxyUpgrader must have the
     *  credentials to upgrade the added proxies
     *  @param name the name to associate the contract with
     *  @param contractAddress the address of the proxy
     */
    function _justAddProxyContract(string memory name, address contractAddress) internal {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
        _isProxy[contractAddress] = true;
    }

    /**
     *  @notice The function to remove the contract from the ContractsRegistry
     *  @param name the associated name with the contract
     */
    function _removeContract(string memory name) internal {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        delete _isProxy[_contracts[name]];
        delete _contracts[name];
    }
}
