// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../../access-control/presets/MultiOwnable.sol";

contract MultiOwnableMock is MultiOwnable {
    function mockInit() external {
        __AbstractMultiOwnable_init();
    }    
}
