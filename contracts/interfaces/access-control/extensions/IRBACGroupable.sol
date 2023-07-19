// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The RBAC module
 */
interface IRBACGroupable {
    event AddedToGroups(address who, string[] groupsToAddTo);
    event RemovedFromGroups(address who, string[] groupsToRemoveFrom);

    event GrantedGroupRoles(string groupTo, string[] rolesToGrant);
    event RevokedGroupRoles(string groupFrom, string[] rolesToRevoke);

    event ToggledDefaultGroup(bool defaultGroupEnabled);

    function addUserToGroups(address who_, string[] calldata groupsToAddTo_) external;

    function removeUserFromGroups(address who_, string[] calldata groupsToRemoveFrom_) external;

    function grantGroupRoles(string calldata groupTo_, string[] calldata rolesToGrant_) external;

    function revokeGroupRoles(
        string calldata groupFrom_,
        string[] calldata rolesToRevoke_
    ) external;

    function toggleDefaultGroup() external;

    function getUserGroups(address who_) external view returns (string[] calldata groups_);

    function getGroupRoles(
        string calldata group_
    ) external view returns (string[] calldata roles_);

    function getDefaultGroupEnabled() external view returns (bool);
}
