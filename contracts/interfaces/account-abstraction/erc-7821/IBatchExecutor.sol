// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Minimal Batch Executor (ERC-7821) module
 */
interface IBatchExecutor {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    error UnsupportedExecutionMode();

    /**
     * @notice A function to execute a batch of calls according to the specified execution mode.
     * @dev Reverts and bubbles up error if any call fails.
            Replaces the `Call.to` with `address(this)` if `address(0)`.
            Supported modes:
                - `0x01000000000000000000...`: Single batch. Does not support optional `opData_`.
                - `0x01000000000078210001...`: Single batch. Supports optional `opData_`.
                - `0x01000000000078210002...`: Batch of batches.
            `executionData_` encoding (single batch):
                - If `opData_` is empty, `executionData_` is simply `abi.encode(calls_)`.
                - Else, `executionData` is `abi.encode(calls_, opData_)`.
            `executionData_` encoding (batch of batches):
                - `executionData` is `abi.encode(bytes[])`, where each element in `bytes[]`
                   is an `executionData_` for a single batch.
     * @param mode_ The execution mode.
     * @param executionData_ Encoded calls with optional `opData_`.
     */
    function execute(bytes32 mode_, bytes memory executionData_) external payable;

    /**
     * @notice A function to compute the EIP-712 hash for a batch call execution request.
     * @param calls_ The batch of calls to hash.
     * @param nonce_ The nonce used in a signature to prevent replay attacks.
     * @return The EIP-712 hash of the batch call execution request.
     */
    function hashBatchExecute(
        Call[] memory calls_,
        uint256 nonce_
    ) external view returns (bytes32);

    /**
     * @notice A function to check whether a provided execution mode is supported.
     * @param mode_ The execution mode to check.
     * @return `true` if the execution mode is supported, `false` otherwise.
     */
    function supportsExecutionMode(bytes32 mode_) external view returns (bool);
}
