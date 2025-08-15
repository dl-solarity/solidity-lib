// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RecoveryProviderMock {
    event SubscribeCalled(bytes recoveryData, uint256 valueAmount);
    event UnsubscribeCalled(uint256 valueAmount);
    event RecoverCalled(bytes object, bytes proof);

    function subscribe(bytes memory recoveryData_) external payable {
        emit SubscribeCalled(recoveryData_, msg.value);
    }

    function unsubscribe() external payable {
        emit UnsubscribeCalled(msg.value);
    }

    function recover(bytes memory object_, bytes memory proof_) external {
        emit RecoverCalled(object_, proof_);
    }
}
