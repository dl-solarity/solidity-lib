// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ADiamondStorage} from "../../diamond/ADiamondStorage.sol";
import {AInitializableStorage} from "../../diamond/utils/AInitializableStorage.sol";

contract InitializableStorageMock is ADiamondStorage, Initializable, AInitializableStorage {
    function __mockOnlyInitializing_init() public onlyDiamondInitializing(DIAMOND_STORAGE_SLOT) {}

    function __mockInitializer_init() public diamondInitializer(DIAMOND_STORAGE_SLOT) {
        __mockOnlyInitializing_init();
    }

    function __mock_reinitializer(
        uint64 version_
    ) public diamondReinitializer(DIAMOND_STORAGE_SLOT, version_) {
        __mockOnlyInitializing_init();
    }

    function disableInitializers() public {
        _disableDiamondInitializers(DIAMOND_STORAGE_SLOT);
    }

    function invalidDisableInitializers() public diamondInitializer(DIAMOND_STORAGE_SLOT) {
        _disableDiamondInitializers(DIAMOND_STORAGE_SLOT);
    }

    function invalidReinitializer(
        uint64 version_
    ) public diamondInitializer(DIAMOND_STORAGE_SLOT) {
        __mock_reinitializer(version_);
    }
}
