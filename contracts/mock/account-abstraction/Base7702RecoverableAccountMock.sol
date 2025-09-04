// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Base7702RecoverableAccount} from "../../account-abstraction/Base7702RecoverableAccount.sol";
import {IBase7702RecoverableAccount} from "../../interfaces/account-abstraction/IBase7702RecoverableAccount.sol";

contract Base7702RecoverableAccountMock is Base7702RecoverableAccount {
    receive() external payable {}
}

contract Base7702RecoverableAccountMockWithHooks is Base7702RecoverableAccount {
    event BeforeBatchCall(Call[] calls_, bytes opData_);
    event AfterBatchCall(Call[] calls_, bytes opData_);
    event BeforeCall(address to_, uint256 value_, bytes data_);
    event AfterCall(address to_, uint256 value_, bytes data_);

    receive() external payable {}

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
    function callUpdate(address account_, address newTrustedExecutor_) external {
        IBase7702RecoverableAccount(account_).updateTrustedExecutor(newTrustedExecutor_, true);
    }
}
