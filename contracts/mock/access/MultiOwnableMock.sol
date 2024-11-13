// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.4;

import {MultiOwnable} from "./../../access/MultiOwnable.sol";

contract MultiOwnableMock is MultiOwnable {
    function __MultiOwnableMock_init() external initializer {
        __MultiOwnable_init();
    }

    function mockInit() external {
        __MultiOwnable_init();
    }
}
