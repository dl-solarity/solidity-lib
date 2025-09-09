// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Base7702RecoverableAccount} from "../../account-abstraction/Base7702RecoverableAccount.sol";

contract Base7702RecoverableAccountMock is Base7702RecoverableAccount {
    constructor(address entryPoint_) Base7702RecoverableAccount(entryPoint_) {}

    function updateTrustedExecutor(address newTrustedExecutor_) external {
        _updateTrustedExecutor(newTrustedExecutor_);
    }
}

contract Base7702RecoverableAccountMockWithHooks is Base7702RecoverableAccountMock {
    event BeforeBatchCall(Call[] calls_, bytes opData_);
    event AfterBatchCall(Call[] calls_, bytes opData_);
    event BeforeCall(address to_, uint256 value_, bytes data_);
    event AfterCall(address to_, uint256 value_, bytes data_);

    constructor(address entryPoint_) Base7702RecoverableAccountMock(entryPoint_) {}

    function _beforeBatchCall(Call[] memory calls_, bytes memory opData_) internal override {
        emit BeforeBatchCall(calls_, opData_);
    }

    function _afterBatchCall(Call[] memory calls_, bytes memory opData_) internal override {
        emit AfterBatchCall(calls_, opData_);
    }

    function _beforeCall(address to_, uint256 value_, bytes memory data_) internal override {
        emit BeforeCall(to_, value_, data_);
    }

    function _afterCall(address to_, uint256 value_, bytes memory data_) internal override {
        emit AfterCall(to_, value_, data_);
    }
}

contract Caller {
    function callAddRecoveryProvider(
        address payable account_,
        address provider_,
        bytes memory recoveryData_
    ) external {
        Base7702RecoverableAccount(account_).addRecoveryProvider(provider_, recoveryData_);
    }
}
