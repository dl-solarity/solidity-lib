// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {RecoverableAccount} from "../../account-abstraction/RecoverableAccount.sol";

contract RecoverableAccountMock is RecoverableAccount {
    function updateTrustedExecutor(address newTrustedExecutor_) external {
        _updateTrustedExecutor(newTrustedExecutor_);
    }
}

contract RecoverableAccountMockWithHooks is RecoverableAccountMock {
    event BeforeCall(address to_, uint256 value_, bytes data_);
    event AfterCall(address to_, uint256 value_, bytes data_);

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
        RecoverableAccount(account_).addRecoveryProvider(provider_, recoveryData_);
    }
}
