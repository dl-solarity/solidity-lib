// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Bridge module
 */
interface IBatcher {
    function execute(bytes calldata batch_) external payable;
}
