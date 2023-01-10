// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 *  @notice The PoolContractsRegistry module
 *
 *  This is a utility lightweighted ProxyBeacon contract this is used as a beacon that BeaconProxies point to.
 */
contract ProxyBeacon is IBeacon {
    using Address for address;

    address private immutable _owner;
    address private _implementation;

    event Upgraded(address indexed implementation);

    modifier onlyOwner() {
        require(_owner == msg.sender, "ProxyBeacon: Not an owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function implementation() external view override returns (address) {
        return _implementation;
    }

    function upgrade(address newImplementation) external onlyOwner {
        require(newImplementation.isContract(), "ProxyBeacon: Not a contract");

        _implementation = newImplementation;

        emit Upgraded(newImplementation);
    }
}
