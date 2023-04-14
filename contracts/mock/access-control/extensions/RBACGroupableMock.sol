// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

import {RBACGroupable} from "../../../access-control/extensions/RBACGroupable.sol";

contract RBACGroupableMock is RBACGroupable {
    using TypeCaster for string;

    function __RBACGroupableMock_init() external initializer {
        __RBACGroupable_init();

        _grantRoles(msg.sender, MASTER_ROLE.asSingletonArray());
    }

    function mockInit() external {
        __RBACGroupable_init();
    }
}
