// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RecoveryProviderMock {
    event SubscribeCalled(bytes recoveryData_);
    event UnsubscribeCalled();
    event RecoverCalled(bytes object, bytes proof);

    function subscribe(bytes memory recoveryData_) external payable {
        emit SubscribeCalled(recoveryData_);
    }

    function unsubscribe() external payable {
        emit UnsubscribeCalled();
    }

    function recover(bytes memory object_, bytes memory proof_) external {
        emit RecoverCalled(object_, proof_);
    }
}
