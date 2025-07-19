// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RecoveryProviderMock {
    event SubscribeCalled(bytes recoveryData_);
    event UnsubscribeCalled();
    event RecoverCalled(address newOwner, bytes proof);

    function subscribe(bytes memory recoveryData_) external {
        emit SubscribeCalled(recoveryData_);
    }

    function unsubscribe() external {
        emit UnsubscribeCalled();
    }

    function recover(address newOwner_, bytes memory proof_) external {
        emit RecoverCalled(newOwner_, proof_);
    }
}
