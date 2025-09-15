// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Batcher module
 */
interface IBatcher {
    /**
     * @notice A function to execute a batch of calls.
     * @dev Reverts if any call fails.
     * @param batch_ encoded tuple of (address[] targets, uint256[] values, bytes[] data).
     */
    function execute(bytes calldata batch_) external payable;
}
