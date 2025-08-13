// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AAccountRecovery} from "../../account-abstraction/AAccountRecovery.sol";

contract AccountRecoveryMock is AAccountRecovery {
    function addRecoveryProvider(
        address provider_,
        bytes memory recoveryData_
    ) external payable override {
        _addRecoveryProvider(provider_, recoveryData_);
    }

    function removeRecoveryProvider(address provider_) external payable override {
        _removeRecoveryProvider(provider_);
    }

    function validateRecovery(
        bytes memory object_,
        address provider_,
        bytes memory proof_
    ) external {
        _validateRecovery(object_, provider_, proof_);
    }

    function recoverAccess(
        bytes memory,
        address,
        bytes memory
    ) external pure override returns (bool) {}
}
