// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {IHandler} from "../../interfaces/bridge/IHandler.sol";

/**
 * @title MessageHandler
 */
contract MessageHandler is IHandler {
    event MessageSent(string network, bytes batch);

    struct MessageDepositData {
        string network;
        bytes batch;
    }

    struct MessageWithdrawData {
        bytes batch;
        bytes32 nonce; // keccak256(abi.encodePacked(origin network name . origin tx hash . event number))
    }

    function deposit(bytes calldata depositDetails_) external virtual {
        MessageDepositData memory deposit_ = abi.decode(depositDetails_, (MessageDepositData));

        emit MessageSent(deposit_.network, deposit_.batch);
    }

    function withdraw(IBatcher batcher_, bytes calldata withdrawDetails_) external virtual {
        MessageWithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (MessageWithdrawData));

        batcher_.execute(withdraw_.batch);
    }

    function getOperationHash(
        string calldata network_,
        bytes calldata withdrawDetails_
    ) external view virtual returns (bytes32) {
        MessageWithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (MessageWithdrawData));

        return
            keccak256(abi.encodePacked(withdraw_.batch, withdraw_.nonce, network_, address(this)));
    }
}
