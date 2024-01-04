// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PermanentOwnable} from "../../access-control/PermanentOwnable.sol";

/**
 * @notice The proxies module
 *
 * This is the lightweight helper contract that may be used as a TransparentProxy admin.
 */
contract TransparentProxyUpgrader is PermanentOwnable {
    using Address for address;

    constructor() PermanentOwnable(msg.sender) {}

    /**
     * @notice The function to upgrade the implementation contract
     * @param what_ the proxy contract to upgrade
     * @param to_ the new implementation contract
     * @param data_ arbitrary data the proxy will be called with after the upgrade
     */
    function upgrade(address what_, address to_, bytes calldata data_) external virtual onlyOwner {
        if (data_.length > 0) {
            ITransparentUpgradeableProxy(payable(what_)).upgradeToAndCall(to_, data_);
        } else {
            ITransparentUpgradeableProxy(payable(what_)).upgradeTo(to_);
        }
    }

    /**
     * @notice The function to get the address of the proxy implementation
     * @param what_ the proxy contract to observe
     * @return the implementation address
     */
    function getImplementation(address what_) public view virtual returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success_, bytes memory returndata_) = address(what_).staticcall(hex"5c60da1b");

        require(success_, "TransparentProxyUpgrader: not a proxy");

        return abi.decode(returndata_, (address));
    }
}
