// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/access-control/extensions/IRBACGroupable.sol";

import "../../libs/arrays/SetHelper.sol";

import "../RBAC.sol";

/**
 *  @notice The Role Based Access Control (RBAC) module
 *
 *  This contract is an extension for the RBAC contract to provide the ability to organize roles
 *  into groups and assign groups to users.
 */
abstract contract RBACGroupable is IRBACGroupable, RBAC {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;

    mapping(address => StringSet.Set) private _userGroups;
    mapping(string => StringSet.Set) private _groupRoles;

    /**
     *  @notice The init function
     */
    function __GroupRBAC_init() internal onlyInitializing {
        __RBAC_init();
    }

    /**
     *  @notice The function to assign groups to the user
     *  @param who_ the user to assign groups to
     *  @param groupsToAddTo_ the list of groups to be assigned
     */
    function addUserToGroups(
        address who_,
        string[] memory groupsToAddTo_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(groupsToAddTo_.length > 0, "RBACGroupable: empty groups");

        _addUserToGroups(who_, groupsToAddTo_);
    }

    /**
     *  @notice The function to remove the user from groups
     *  @param who_ the user to be removed from groups
     *  @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function removeUserFromGroups(
        address who_,
        string[] memory groupsToRemoveFrom_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(groupsToRemoveFrom_.length > 0, "RBACGroupable: empty groups");

        _removeUserFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     *  @notice The function to grant roles to the group
     *  @param groupTo_ the group to grant roles to
     *  @param rolesToGrant_ the list of roles to grant
     */
    function grantGroupRoles(
        string memory groupTo_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBACGroupable: empty roles");

        _grantGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     *  @notice The function to revoke roles from the group
     *  @param groupFrom_ the group to revoke roles from
     *  @param rolesToRevoke_ the list of roles to revoke
     */
    function revokeGroupRoles(
        string memory groupFrom_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBACGroupable: empty roles");

        _revokeGroupRoles(groupFrom_, rolesToRevoke_);
    }

    /**
     *  @notice The function to get the list of user groups
     *  @param who_ the user
     *  @return groups_ the list of user groups
     */
    function getUserGroups(address who_) public view override returns (string[] memory groups_) {
        return _userGroups[who_].values();
    }

    /**
     *  @notice The function to get the list of groups roles
     *  @param group_ the group
     *  @return roles_ the list of group roles
     */
    function getGroupRoles(
        string memory group_
    ) public view override returns (string[] memory roles_) {
        return _groupRoles[group_].values();
    }

    /**
     *  @notice The internal function to assign groups to the user
     *  @param who_ the user to assign groups to
     *  @param groupsToAddTo_ the list of groups to be assigned
     */
    function _addUserToGroups(address who_, string[] memory groupsToAddTo_) internal {
        _userGroups[who_].add(groupsToAddTo_);

        emit AddedToGroups(who_, groupsToAddTo_);
    }

    /**
     *  @notice The internal function to remove the user from groups
     *  @param who_ the user to be removed from groups
     *  @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function _removeUserFromGroups(address who_, string[] memory groupsToRemoveFrom_) internal {
        _userGroups[who_].remove(groupsToRemoveFrom_);

        emit RemovedFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     *  @notice The internal function to grant roles to the group
     *  @param groupTo_ the group to grant roles to
     *  @param rolesToGrant_ the list of roles to grant
     */
    function _grantGroupRoles(string memory groupTo_, string[] memory rolesToGrant_) internal {
        _groupRoles[groupTo_].add(rolesToGrant_);

        emit GrantedGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     *  @notice The internal function to revoke roles from the group
     *  @param groupFrom_ the group to revoke roles from
     *  @param rolesToRevoke_ the list of roles to revoke
     */
    function _revokeGroupRoles(string memory groupFrom_, string[] memory rolesToRevoke_) internal {
        _groupRoles[groupFrom_].remove(rolesToRevoke_);

        emit RevokedGroupRoles(groupFrom_, rolesToRevoke_);
    }

    /**
     *  @notice The internal function to check the user permission status. Unlike the base method,
     *  this method also looks up the required permission in the user's groups
     *  @param who_ the user
     *  @param resource_ the resource the user has to have the permission of
     *  @param permission_ the permission the user has to have
     *  @return userPermissionStatus_ the user permission status
     */
    function _hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) internal view virtual override returns (PermissionStatus userPermissionStatus_) {
        userPermissionStatus_ = super._hasPermission(who_, resource_, permission_);

        if (userPermissionStatus_ == PermissionStatus.Disallows) {
            return PermissionStatus.Disallows;
        }

        string[] memory groups_ = getUserGroups(who_);

        for (uint256 i = 0; i < groups_.length; i++) {
            PermissionStatus rolesPermissionStatus_ = _hasRolesPermission(
                getGroupRoles(groups_[i]),
                resource_,
                permission_
            );

            if (rolesPermissionStatus_ == PermissionStatus.Disallows) {
                return PermissionStatus.Disallows;
            }

            if (rolesPermissionStatus_ == PermissionStatus.Allows) {
                userPermissionStatus_ = rolesPermissionStatus_;
            }
        }
    }
}
