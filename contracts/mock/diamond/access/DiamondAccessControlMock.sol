// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DiamondAccessControl} from "../../../diamond/access/access-control/DiamondAccessControl.sol";

contract DiamondAccessControlMock is DiamondAccessControl {
    bytes32 public constant AGENT_ROLE = bytes32(uint256(0x01));

    function __DiamondAccessControlDirect_init() external {
        __DiamondAccessControl_init();
    }

    function __DiamondAccessControlMock_init()
        external
        initializer(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
    {
        __DiamondAccessControl_init();
    }

    function setRoleAdmin(
        bytes32 role_,
        bytes32 adminRole_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role_, adminRole_);
    }
}
