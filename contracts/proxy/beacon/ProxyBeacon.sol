// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice The proxies module
 *
 * This is a lightweight utility ProxyBeacon contract that may be used as a beacon that BeaconProxies point to.
 */
contract ProxyBeacon is IBeacon {
    using Address for address;

    address private immutable _OWNER;

    address private _implementation;

    event Upgraded(address implementation);

    modifier onlyOwner() {
        require(_OWNER == msg.sender, "ProxyBeacon: not an owner");
        _;
    }

    constructor() {
        _OWNER = msg.sender;
    }

    function upgradeTo(address newImplementation_) external virtual onlyOwner {
        require(newImplementation_.isContract(), "ProxyBeacon: not a contract");

        _implementation = newImplementation_;

        emit Upgraded(newImplementation_);
    }

    function implementation() public view virtual override returns (address) {
        return _implementation;
    }
}
