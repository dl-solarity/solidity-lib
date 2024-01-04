// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PermanentOwnable} from "../../access-control/PermanentOwnable.sol";

/**
 * @notice The proxies module
 *
 * This is a lightweight utility ProxyBeacon contract that may be used as a beacon that BeaconProxies point to.
 */
contract ProxyBeacon is IBeacon, PermanentOwnable {
    using Address for address;

    constructor() PermanentOwnable(msg.sender) {}

    address private _implementation;

    event Upgraded(address implementation);

    /**
     * @notice The function to upgrade to implementation contract
     * @param newImplementation_ the new implementation
     */
    function upgradeTo(address newImplementation_) external virtual onlyOwner {
        require(newImplementation_.isContract(), "ProxyBeacon: not a contract");

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
