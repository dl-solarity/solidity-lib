// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {AMultiOwnable} from "./../../access/AMultiOwnable.sol";

contract MultiOwnableMock is AMultiOwnable {
    function __MultiOwnableMock_init() external initializer {
        __AMultiOwnable_init();
    }

    function __MultiOwnableMockMulti_init(address[] memory initialOwners_) external initializer {
        __AMultiOwnable_init(initialOwners_);
    }

    function mockInit() external {
        __AMultiOwnable_init();
    }
}
