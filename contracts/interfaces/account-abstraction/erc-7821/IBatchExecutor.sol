// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IBatchExecutor {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    error UnsupportedExecutionMode();

    function execute(bytes32 mode_, bytes memory executionData_) external payable;

    function hashBatchExecute(
        Call[] memory calls_,
        uint256 nonce_
    ) external view returns (bytes32);

    function supportsExecutionMode(bytes32 mode_) external view returns (bool);
}
