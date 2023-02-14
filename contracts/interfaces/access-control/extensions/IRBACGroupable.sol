// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRBACGroupable {
    event AddedToGroups(address who, string[] groupsToAddTo);
    event RemovedFromGroups(address who, string[] groupsToRemoveFrom);

    event GrantedGroupRoles(string groupTo, string[] rolesToGrant);
    event RevokedGroupRoles(string groupFrom, string[] rolesToRevoke);

    function addUserToGroups(address who_, string[] memory groupsToAddTo_) external;

    function removeUserFromGroups(address who_, string[] memory groupsToRemoveFrom_) external;

    function grantGroupRoles(string calldata groupTo_, string[] memory rolesToGrant_) external;

    function revokeGroupRoles(string calldata groupFrom_, string[] memory rolesToRevoke_) external;

    function getUserGroups(address who_) external view returns (string[] memory groups_);

    function getGroupRoles(string memory group_) external view returns (string[] memory roles_);
}
