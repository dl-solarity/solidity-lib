// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MultiOwnable} from "./../../access-control/MultiOwnable.sol";

contract MultiOwnableMock is MultiOwnable {
    function __MultiOwnableMock_init() external initializer {
        __MultiOwnable_init();
    }

    function mockInit() external {
        __MultiOwnable_init();
    }
}
