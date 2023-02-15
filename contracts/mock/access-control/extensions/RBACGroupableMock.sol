// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../access-control/extensions/RBACGroupable.sol";

contract RBACMockGroupableMock is RBACGroupable {
    using ArrayHelper for string;

    function __RBACMock_init() external initializer {
        __RBACGroupable_init();

        _grantRoles(msg.sender, MASTER_ROLE.asArray());
    }

    function mockInit() external {
        __RBAC_init();
    }
}
