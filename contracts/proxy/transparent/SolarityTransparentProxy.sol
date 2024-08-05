// SPDX-License-Identifier: MIT
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/proxy/transparent/TransparentUpgradeableProxy.sol

pragma solidity ^0.8.4;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

/**
 * @notice The proxies module
 *
 * Interface for SolarityTransparentProxy.
 **/
interface ISolarityTransparentProxy is IERC1967 {
    /**
     * @notice The function to upgrade the implementation contract with additional setup call if data is nonempty.
     */
    function upgradeToAndCall(address, bytes calldata) external payable;

    /**
     * @notice The function to return the current implementation address.
     */
    function implementation() external returns (address);
}

/**
 * @notice This contract implements a proxy that is upgradeable by an admin.
 *
 * The implementation of this contract is based on OpenZeppelin's TransparentUpgradeableProxy.
 * The main change is in the constructor. While the original contract deploys an instance of ProxyAdmin
 * for every proxy, this implementation simply sets the specified address as the admin.
 * Additionally, an implementation function has been added.
 *
 * For more information about proxy logic, please refer to the OpenZeppelin documentation.
 */
contract SolarityTransparentProxy is ERC1967Proxy {
    address private immutable _admin;

    error ProxyDeniedAdminAccess();

    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable ERC1967Proxy(logic_, data_) {
        _admin = admin_;
        ERC1967Utils.changeAdmin(admin_);
    }

    function _fallback() internal virtual override {
        if (msg.sender == _admin) {
            bytes4 selector_ = msg.sig;

            if (selector_ == ISolarityTransparentProxy.upgradeToAndCall.selector) {
                _dispatchUpgradeToAndCall();
            } else if (selector_ == ISolarityTransparentProxy.implementation.selector) {
                bytes memory returndata_ = _dispatchImplementation();

                assembly {
                    return(add(returndata_, 0x20), mload(returndata_))
                }
            } else {
                revert ProxyDeniedAdminAccess();
            }
        } else {
            super._fallback();
        }
    }

    function _dispatchUpgradeToAndCall() private {
        (address newImplementation_, bytes memory data_) = abi.decode(
            msg.data[4:],
            (address, bytes)
        );
        ERC1967Utils.upgradeToAndCall(newImplementation_, data_);
    }

    function _dispatchImplementation() private view returns (bytes memory) {
        return abi.encode(_implementation());
    }
}
