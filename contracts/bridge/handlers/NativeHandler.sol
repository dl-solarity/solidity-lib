// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {IHandler} from "../../interfaces/bridge/IHandler.sol";

/**
 * @title NativeHandler
 */
contract NativeHandler is IHandler {
    using Address for address payable;

    event DispatchedNative(uint256 amount, string receiver, string network, bytes batch);

    struct NativeDispatchData {
        string receiver;
        string network;
        bytes batch;
    }

    /**
     * @dev Nonce is computed as keccak256(abi.encodePacked(originNetworkName, originTxHash, eventNumber)).
     */
    struct NativeRedeemData {
        uint256 amount;
        address receiver;
        bytes batch;
        bytes32 nonce;
    }

    /**
     * @inheritdoc IHandler
     */
    function dispatch(bytes calldata dispatchDetails_) external payable virtual {
        NativeDispatchData memory dispatch_ = abi.decode(dispatchDetails_, (NativeDispatchData));

        _dispatch(dispatch_);

        emit DispatchedNative(msg.value, dispatch_.receiver, dispatch_.network, dispatch_.batch);
    }

    /**
     * @inheritdoc IHandler
     */
    function redeem(IBatcher batcher_, bytes calldata redeemDetails_) external virtual {
        NativeRedeemData memory redeem_ = abi.decode(redeemDetails_, (NativeRedeemData));

        if (redeem_.batch.length == 0) {
            _redeem(redeem_);
            return;
        }

        redeem_.receiver = address(batcher_);

        _redeem(redeem_);
        batcher_.execute(redeem_.batch);
    }

    /**
     * @inheritdoc IHandler
     */
    function getOperationHash(
        string calldata network_,
        bytes calldata redeemDetails_
    ) external view virtual returns (bytes32) {
        NativeRedeemData memory redeem_ = abi.decode(redeemDetails_, (NativeRedeemData));

        return
            keccak256(
                abi.encodePacked(
                    redeem_.amount,
                    redeem_.receiver,
                    redeem_.batch,
                    redeem_.nonce,
                    network_,
                    address(this)
                )
            );
    }

    function _dispatch(NativeDispatchData memory) internal virtual {
        if (msg.value == 0) revert ZeroAmount();
    }

    function _redeem(NativeRedeemData memory redeem_) internal virtual {
        if (redeem_.amount == 0) revert ZeroAmount();
        if (redeem_.receiver == address(0)) revert ZeroReceiver();

        payable(redeem_.receiver).sendValue(redeem_.amount);
    }
}
