// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libs/data-structures/StringSet.sol";

/**
 *  @notice The RBAC module
 */
interface IRBAC {
    struct ResourceWithPermissions {
        string resource;
        string[] permissions;
    }

    function grantRoles(address to, string[] memory rolesToGrant) external;

    function revokeRoles(address from, string[] memory rolesToRevoke) external;

    function addPermissionsToRole(
        string calldata role,
        ResourceWithPermissions[] calldata permissionsToAdd,
        bool allowed
    ) external;

    function removePermissionsFromRole(
        string calldata role,
        ResourceWithPermissions[] calldata permissionsToRemove,
        bool allowed
    ) external;

    function getUserRoles(address who) external view returns (string[] memory roles);

    function getRolePermissions(
        string calldata role
    )
        external
        view
        returns (
            ResourceWithPermissions[] calldata allowed,
            ResourceWithPermissions[] calldata disallowed
        );

    function hasPermission(
        address who,
        string calldata resource,
        string calldata permission
    ) external view returns (bool);
}
