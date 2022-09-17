// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libs/data-structures/StringSet.sol";
import "../libs/arrays/ArrayHelper.sol";
import "../libs/arrays/SetHelper.sol";

contract RBAC is Initializable {
    using StringSet for StringSet.Set;
    using ArrayHelper for string;
    using SetHelper for StringSet.Set;

    string public constant MASTER_ROLE = "MASTER";

    string public constant ALL_PERMISSION = "*";
    string public constant RBAC_CRUD_PERMISSION = "RBAC.crud";

    mapping(string => StringSet.Set) private _roleAllowedPermissions;
    mapping(string => StringSet.Set) private _roleDisallowedPermissions;

    mapping(address => StringSet.Set) private _userRoles;

    modifier onlyPermission(string memory permission) {
        require(
            hasPermission(msg.sender, permission),
            string.concat("RBAC: no ", permission, " permission")
        );
        _;
    }

    function __RBAC_init() internal onlyInitializing {
        _addPermissionsToRole(MASTER_ROLE, ALL_PERMISSION.asArray(), true);
    }

    function grantRoles(address to, string[] memory rolesToGrant)
        public
        onlyPermission(RBAC_CRUD_PERMISSION)
    {
        _grantRoles(to, rolesToGrant);
    }

    function revokeRoles(address to, string[] memory rolesToRevoke)
        public
        onlyPermission(RBAC_CRUD_PERMISSION)
    {
        _revokeRoles(to, rolesToRevoke);
    }

    function addPermissionsToRole(
        string memory role,
        string[] memory permissionsToAdd,
        bool allowed
    ) public onlyPermission(RBAC_CRUD_PERMISSION) {
        _addPermissionsToRole(role, permissionsToAdd, allowed);
    }

    function removePermissionsFromRole(
        string memory role,
        string[] memory permissionsToRemove,
        bool allowed
    ) public onlyPermission(RBAC_CRUD_PERMISSION) {
        _removePermissionsFromRole(role, permissionsToRemove, allowed);
    }

    function getUserRoles(address who) public view returns (string[] memory roles) {
        return _userRoles[who].values();
    }

    function getRolePermissions(string memory role)
        public
        view
        returns (string[] memory allowedPermissions, string[] memory disallowedPermissions)
    {
        return (_roleAllowedPermissions[role].values(), _roleDisallowedPermissions[role].values());
    }

    function hasPermission(address who, string memory permission) public view returns (bool) {
        StringSet.Set storage roles = _userRoles[who];

        uint256 length = roles.length();
        bool isAllowed;

        for (uint256 i = 0; i < length; i++) {
            StringSet.Set storage disallowedPermissions = _roleDisallowedPermissions[roles.at(i)];
            StringSet.Set storage allowedPermissions = _roleAllowedPermissions[roles.at(i)];

            if (
                disallowedPermissions.contains(ALL_PERMISSION) ||
                disallowedPermissions.contains(permission)
            ) {
                return false;
            }

            if (
                allowedPermissions.contains(ALL_PERMISSION) ||
                allowedPermissions.contains(permission)
            ) {
                isAllowed = true;
            }
        }

        return isAllowed;
    }

    function _grantRoles(address to, string[] memory rolesToGrant) internal {
        _userRoles[to].add(rolesToGrant);
    }

    function _revokeRoles(address to, string[] memory rolesToRevoke) internal {
        _userRoles[to].remove(rolesToRevoke);
    }

    function _addPermissionsToRole(
        string memory role,
        string[] memory permissionsToAdd,
        bool allowed
    ) internal {
        StringSet.Set storage permissions = allowed
            ? _roleAllowedPermissions[role]
            : _roleDisallowedPermissions[role];

        permissions.add(permissionsToAdd);
    }

    function _removePermissionsFromRole(
        string memory role,
        string[] memory permissionsToRemove,
        bool allowed
    ) internal {
        StringSet.Set storage permissions = allowed
            ? _roleAllowedPermissions[role]
            : _roleDisallowedPermissions[role];

        permissions.remove(permissionsToRemove);
    }
}
