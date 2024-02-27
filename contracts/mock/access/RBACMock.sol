// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TypeCaster} from "../../libs/utils/TypeCaster.sol";

import {RBAC} from "../../access/RBAC.sol";

contract RBACMock is RBAC {
    using TypeCaster for string;

    function __RBACMock_init() external initializer {
        __RBAC_init();

        _grantRoles(msg.sender, MASTER_ROLE.asSingletonArray());
    }

    function mockInit() external {
        __RBAC_init();
    }
}
