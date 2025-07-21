// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AAccountRecovery} from "../../account-abstraction/AAccountRecovery.sol";

contract AccountRecoveryMock is AAccountRecovery {
    function addRecoveryProvider(address provider_, bytes memory recoveryData_) external override {
        _addRecoveryProvider(provider_, recoveryData_);
    }

    function removeRecoveryProvider(address provider_) external override {
        _removeRecoveryProvider(provider_);
    }

    function validateRecovery(address newOwner_, address provider_, bytes memory proof_) external {
        _validateRecovery(newOwner_, provider_, proof_);
    }

    function recoverOwnership(
        address,
        address,
        bytes memory
    ) external pure override returns (bool) {}
}
