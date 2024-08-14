// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {PermanentOwnable} from "../../access/PermanentOwnable.sol";

/**
 * @notice The proxies module
 *
 * This is a lightweight utility ProxyBeacon contract that may be used as a beacon that BeaconProxies point to.
 */
contract ProxyBeacon is IBeacon, PermanentOwnable {
    constructor() PermanentOwnable(msg.sender) {}

    address private _implementation;

    event Upgraded(address implementation);

    error ProxyBeaconNotContract();

    /**
     * @notice The function to upgrade to implementation contract
     * @param newImplementation_ the new implementation
     */
    function upgradeTo(address newImplementation_) external virtual onlyOwner {
        if (newImplementation_.code.length == 0) {
            revert ProxyBeaconNotContract();
        }

        _implementation = newImplementation_;

        emit Upgraded(newImplementation_);
    }

    /**
     * @notice The function to get the address of the implementation contract
     * @return the address of the implementation contract
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }
}
