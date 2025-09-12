// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBatcher} from "./IBatcher.sol";

interface IBaseHandler {
    error ZeroToken();
    error ZeroReceiver();
    error ZeroAmount();

    function withdraw(IBatcher batcher_, bytes calldata withdrawDetails_) external;

    function getOperationHash(
        string calldata network_,
        bytes calldata withdrawDetails_
    ) external view returns (bytes32);
}

interface IHandler is IBaseHandler {
    function deposit(bytes calldata depositDetails_) external;
}

interface INativeHandler is IBaseHandler {
    function deposit(bytes calldata depositDetails_) external payable;
}
