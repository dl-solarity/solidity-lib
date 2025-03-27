// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ADiamondStorage} from "../../diamond/ADiamondStorage.sol";
import {AInitializableStorage} from "../../diamond/utils/AInitializableStorage.sol";

contract InitializableStorageMock is ADiamondStorage, AInitializableStorage {
    function __mockOnlyInitializing_init() public onlyInitializing(DIAMOND_STORAGE_SLOT) {}

    function __mockInitializer_init() public initializer(DIAMOND_STORAGE_SLOT) {
        __mockOnlyInitializing_init();
    }

    function __mock_reinitializer(
        uint64 version_
    ) public reinitializer(DIAMOND_STORAGE_SLOT, version_) {
        __mockOnlyInitializing_init();
    }

    function disableInitializers() public {
        _disableInitializers(DIAMOND_STORAGE_SLOT);
    }

    function invalidDisableInitializers() public initializer(DIAMOND_STORAGE_SLOT) {
        _disableInitializers(DIAMOND_STORAGE_SLOT);
    }

    function invalidReinitializer(uint64 version_) public initializer(DIAMOND_STORAGE_SLOT) {
        __mock_reinitializer(version_);
    }
}
