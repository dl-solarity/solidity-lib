// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @notice The Diamond standard module
 *
 * This is an AccessControl Storage contract with Diamond Standard support
 */
abstract contract DiamondAccessControlStorage is IAccessControl {
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

    function _getAccessControlStorage() internal pure returns (DACStorage storage _dacStorage) {
        bytes32 slot_ = DIAMOND_ACCESS_CONTROL_STORAGE_SLOT;

        assembly {
            _dacStorage.slot := slot_
        }
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _getAccessControlStorage().roles[role].members[account];
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _getAccessControlStorage().roles[role].adminRole;
    }
}
