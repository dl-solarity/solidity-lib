// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableSBT} from "./../../tokens/presets/OwnableSBT.sol";

contract SBTMock is OwnableSBT {
    function mockInit() external {
        __SBT_init();
    }
}
