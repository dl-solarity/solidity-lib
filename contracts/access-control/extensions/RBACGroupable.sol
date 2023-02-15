// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/access-control/extensions/IRBACGroupable.sol";

import "../../libs/arrays/SetHelper.sol";

import "../RBAC.sol";

abstract contract RBACGroupable is RBAC, IRBACGroupable {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;

    mapping(address => StringSet.Set) private _userGroups;
    mapping(string => StringSet.Set) private _groupRoles;

    function __GroupRBAC_init() internal onlyInitializing {
        __RBAC_init();
    }

    function addUserToGroups(
        address who_,
        string[] memory groupsToAddTo_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(groupsToAddTo_.length > 0, "RBACGroupable: empty groups");

        _addUserToGroups(who_, groupsToAddTo_);
    }

    function removeUserFromGroups(
        address who_,
        string[] memory groupsToRemoveFrom_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(groupsToRemoveFrom_.length > 0, "RBACGroupable: empty groups");

        _removeUserFromGroups(who_, groupsToRemoveFrom_);
    }

    function grantGroupRoles(
        string memory groupTo_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBACGroupable: empty roles");

        _grantGroupRoles(groupTo_, rolesToGrant_);
    }

    function revokeGroupRoles(
        string memory groupFrom_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBACGroupable: empty roles");

        _revokeGroupRoles(groupFrom_, rolesToRevoke_);
    }

    function getUserGroups(address who_) public view override returns (string[] memory groups_) {
        return _userGroups[who_].values();
    }

    function getGroupRoles(
        string memory group_
    ) public view override returns (string[] memory roles_) {
        return _groupRoles[group_].values();
    }

    function _addUserToGroups(address who_, string[] memory groupsToAddTo_) internal {
        _userGroups[who_].add(groupsToAddTo_);

        emit AddedToGroups(who_, groupsToAddTo_);
    }

    function _removeUserFromGroups(address who_, string[] memory groupsToRemoveFrom_) internal {
        _userGroups[who_].remove(groupsToRemoveFrom_);

        emit RemovedFromGroups(who_, groupsToRemoveFrom_);
    }

    function _grantGroupRoles(string memory groupTo_, string[] memory rolesToGrant_) internal {
        _groupRoles[groupTo_].add(rolesToGrant_);

        emit GrantedGroupRoles(groupTo_, rolesToGrant_);
    }

    function _revokeGroupRoles(string memory groupFrom_, string[] memory rolesToRevoke_) internal {
        _groupRoles[groupFrom_].remove(rolesToRevoke_);

        emit RevokedGroupRoles(groupFrom_, rolesToRevoke_);
    }

    function _hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) internal view virtual override returns (PermissionStatus userPermissionStatus_) {
        userPermissionStatus_ = super._hasPermission(who_, resource_, permission_);

        if (userPermissionStatus_ == PermissionStatus.DisallowsPermission) {
            return userPermissionStatus_;
        }

        string[] memory groups_ = getUserGroups(who_);

        for (uint256 i = 0; i < groups_.length; i++) {
            PermissionStatus rolesPermissionStatus_ = _getRolesPermissionStatus(
                getGroupRoles(groups_[i]),
                resource_,
                permission_
            );

            if (rolesPermissionStatus_ == PermissionStatus.DisallowsPermission) {
                return rolesPermissionStatus_;
            }

            if (rolesPermissionStatus_ == PermissionStatus.AllowsPermission) {
                userPermissionStatus_ = rolesPermissionStatus_;
            }
        }
    }
}
