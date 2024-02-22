// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {DiamondAccessControlStorage, IAccessControl} from "./DiamondAccessControlStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's AccessControl contract to be used as a Storage contract
 * by the Diamond Standard.
 */
abstract contract DiamondAccessControl is DiamondAccessControlStorage {
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

    /**
     * @notice Sets `DEFAULT_ADMIN_ROLE` to `msg.sender`
     */
    function __DiamondAccessControl_init()
        internal
        onlyInitializing(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role_,
        address account_
    ) public virtual override onlyRole(getRoleAdmin(role_)) {
        _grantRole(role_, account_);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role_,
        address account_
    ) public virtual override onlyRole(getRoleAdmin(role_)) {
        _revokeRole(role_, account_);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role_, address account_) public virtual override {
        require(account_ == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role_, account_);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role_, bytes32 adminRole_) internal virtual {
        bytes32 previousAdminRole_ = getRoleAdmin(role_);
        _getAccessControlStorage().roles[role_].adminRole = adminRole_;
        emit RoleAdminChanged(role_, previousAdminRole_, adminRole_);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role_, address account_) internal virtual {
        if (!hasRole(role_, account_)) {
            _getAccessControlStorage().roles[role_].members[account_] = true;
            emit RoleGranted(role_, account_, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role_, address account_) internal virtual {
        if (hasRole(role_, account_)) {
            _getAccessControlStorage().roles[role_].members[account_] = false;
            emit RoleRevoked(role_, account_, msg.sender);
        }
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

    /**_
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
