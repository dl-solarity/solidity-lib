// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../constants-registry/presets/OwnableConstantsRegistry.sol";

contract ConstantsRegistryMock is OwnableConstantsRegistry {
    function mockInit() external {
        __ConstantsRegistry_init();
    }
}
