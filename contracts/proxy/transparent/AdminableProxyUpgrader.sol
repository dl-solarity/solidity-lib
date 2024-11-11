// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PermanentOwnable} from "../../access/PermanentOwnable.sol";
import {IAdminableProxy} from "./AdminableProxy.sol";

/**
 * @notice The proxies module
 *
 * This is the lightweight helper contract that may be used as a AdminableProxy admin.
 */
contract AdminableProxyUpgrader is PermanentOwnable {
    error AddressNotAProxy(address contractAddress);

    constructor() PermanentOwnable(msg.sender) {}

    /**
     * @notice The function to upgrade the implementation contract
     * @param what_ the proxy contract to upgrade
     * @param to_ the new implementation contract
     * @param data_ arbitrary data the proxy will be called with after the upgrade
     */
    function upgrade(address what_, address to_, bytes calldata data_) external virtual onlyOwner {
        IAdminableProxy(payable(what_)).upgradeToAndCall(to_, data_);
    }

    /**
     * @notice The function to get the address of the proxy implementation
     * @param what_ the proxy contract to observe
     * @return the implementation address
     */
    function getImplementation(address what_) public view virtual returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success_, bytes memory returndata_) = address(what_).staticcall(hex"5c60da1b");

        if (!success_) revert AddressNotAProxy(what_);

        return abi.decode(returndata_, (address));
    }
}
