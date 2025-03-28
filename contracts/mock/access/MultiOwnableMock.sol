// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {AMultiOwnable} from "../../access/AMultiOwnable.sol";

import {TypeCaster} from "../../libs/utils/TypeCaster.sol";

contract MultiOwnableMock is AMultiOwnable {
    using TypeCaster for address;

    function __MultiOwnableMock_init() external initializer {
        __AMultiOwnable_init();
    }

    function __MultiOwnableMockMulti_init(address[] memory initialOwners_) external initializer {
        __AMultiOwnable_init(initialOwners_);
    }

    function mockInit() external {
        __AMultiOwnable_init();
    }

    function mockMultiInit() external {
        __AMultiOwnable_init(msg.sender.asSingletonArray());
    }
}
