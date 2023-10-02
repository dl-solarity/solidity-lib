// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice The ContractsRegistry module
 *
 * This is the helper contract that is used by an AbstractContractsRegistry as a proxy admin.
 * It is essential to distinguish between the admin and the registry due to the Transparent proxies nature
 */
contract ProxyUpgrader {
    using Address for address;

    address private immutable _OWNER;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    constructor() {
        _OWNER = msg.sender;
    }

    function upgrade(address what_, address to_, bytes calldata data_) external onlyOwner {
        if (data_.length > 0) {
            ITransparentUpgradeableProxy(payable(what_)).upgradeToAndCall(to_, data_);
        } else {
            ITransparentUpgradeableProxy(payable(what_)).upgradeTo(to_);
        }
    }

    function getImplementation(address what_) external view onlyOwner returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success_, bytes memory returndata_) = address(what_).staticcall(hex"5c60da1b");

        require(success_, "ProxyUpgrader: not a proxy");

        return abi.decode(returndata_, (address));
    }

    function _onlyOwner() internal view {
        require(_OWNER == msg.sender, "ProxyUpgrader: not an owner");
    }
}
