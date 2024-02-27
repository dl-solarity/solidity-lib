// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {InitializableStorage} from "../../utils/InitializableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is an AccessControl Storage contract with Diamond Standard support
 */
abstract contract DiamondAccessControlStorage is IAccessControl, InitializableStorage {
    bytes32 public constant DIAMOND_ACCESS_CONTROL_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.access.control.storage");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct DACStorage {
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    modifier onlyRole(bytes32 role_) {
        _checkRole(role_);
        _;
    }

    function _getAccessControlStorage() internal pure returns (DACStorage storage _dacStorage) {
        bytes32 slot_ = DIAMOND_ACCESS_CONTROL_STORAGE_SLOT;

        assembly {
            _dacStorage.slot := slot_
        }
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(bytes32 role_, address account_) public view virtual override returns (bool) {
        return _getAccessControlStorage().roles[role_].members[account_];
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role_) public view virtual override returns (bytes32) {
        return _getAccessControlStorage().roles[role_].adminRole;
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     */
    function _checkRole(bytes32 role_) internal view virtual {
        _checkRole(role_, msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role_, address account_) internal view virtual {
        if (!hasRole(role_, account_)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account_),
                        " is missing role ",
                        Strings.toHexString(uint256(role_), 32)
                    )
                )
            );
        }
    }
}
