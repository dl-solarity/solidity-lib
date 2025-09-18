// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {IHandler} from "../../interfaces/bridge/IHandler.sol";

/**
 * @title MessageHandler
 */
contract MessageHandler is IHandler {
    event DispatchedMessage(string network, bytes batch);

    struct MessageDispatchData {
        string network;
        bytes batch;
    }

    /**
     * @dev Nonce is computed as keccak256(abi.encodePacked(originNetworkName, originTxHash, eventNumber)).
     */
    struct MessageRedeemData {
        bytes batch;
        bytes32 nonce;
    }

    /**
     * @inheritdoc IHandler
     */
    function dispatch(bytes calldata dispatchDetails_) external payable virtual {
        MessageDispatchData memory dispatch_ = abi.decode(dispatchDetails_, (MessageDispatchData));

        emit DispatchedMessage(dispatch_.network, dispatch_.batch);
    }

    /**
     * @inheritdoc IHandler
     */
    function redeem(IBatcher batcher_, bytes calldata redeemDetails_) external virtual {
        MessageRedeemData memory redeem_ = abi.decode(redeemDetails_, (MessageRedeemData));

        batcher_.execute(redeem_.batch);
    }

    /**
     * @inheritdoc IHandler
     */
    function getOperationHash(
        string calldata network_,
        bytes calldata redeemDetails_
    ) external view virtual returns (bytes32) {
        MessageRedeemData memory redeem_ = abi.decode(redeemDetails_, (MessageRedeemData));

        return keccak256(abi.encodePacked(redeem_.batch, redeem_.nonce, network_, address(this)));
    }
}
