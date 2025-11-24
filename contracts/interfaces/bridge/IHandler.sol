// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBridge} from "./IBridge.sol";
import {IBatcher} from "./IBatcher.sol";

/**
 * @notice The Bridge Handler module
 */
interface IHandler {
    error ZeroToken();
    error ZeroReceiver();
    error ZeroAmount();

    /**
     * @notice A function to dispatch assets or messages from the origin chain.
     * @param dispatchDetails_ encoded data defining the dispatch operation.
     */
    function dispatch(bytes calldata dispatchDetails_) external payable;

    /**
     * @notice A function to redeem assets or messages on the destination chain.
     * @param batcher_ the batcher contract coordinating batched executions.
     * @param redeemDetails_ encoded data defining the redeem operation.
     */
    function redeem(IBatcher batcher_, bytes calldata redeemDetails_) external;

    /**
     * @notice A function to compute a redeem operation hash used for signing.
     * @param bridge_ the bridge contract.
     * @param network_ the network name.
     * @param redeemDetails_ encoded redeem operation details.
     * @return Operation hash to be signed by bridge signers.
     */
    function getOperationHash(
        IBridge bridge_,
        string calldata network_,
        bytes calldata redeemDetails_
    ) external view returns (bytes32);
}
