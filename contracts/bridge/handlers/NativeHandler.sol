// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {INativeHandler} from "../../interfaces/bridge/IHandler.sol";

/**
 * @title NativeHandler
 */
contract NativeHandler is INativeHandler {
    using Address for address payable;

    receive() external payable {}

    event DepositedNative(uint256 amount, string receiver, string network, bytes batch);

    struct NativeDepositData {
        string receiver;
        string network;
        bytes batch;
    }

    struct NativeWithdrawData {
        uint256 amount;
        address receiver;
        bytes batch;
        bytes32 nonce; // keccak256(abi.encodePacked(origin network name . origin tx hash . event number))
    }

    function deposit(bytes calldata depositDetails_) external payable virtual {
        NativeDepositData memory deposit_ = abi.decode(depositDetails_, (NativeDepositData));

        _deposit(deposit_);

        emit DepositedNative(msg.value, deposit_.receiver, deposit_.network, deposit_.batch);
    }

    function withdraw(IBatcher batcher_, bytes calldata withdrawDetails_) external virtual {
        NativeWithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (NativeWithdrawData));

        if (withdraw_.batch.length == 0) {
            _withdraw(withdraw_);
            return;
        }

        withdraw_.receiver = address(batcher_);

        _withdraw(withdraw_);
        batcher_.execute(withdraw_.batch);
    }

    function getOperationHash(
        string calldata network_,
        bytes calldata withdrawDetails_
    ) external view virtual returns (bytes32) {
        NativeWithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (NativeWithdrawData));

        return
            keccak256(
                abi.encodePacked(
                    withdraw_.amount,
                    withdraw_.receiver,
                    withdraw_.batch,
                    withdraw_.nonce,
                    network_,
                    address(this)
                )
            );
    }

    function _deposit(NativeDepositData memory) internal virtual {
        if (msg.value == 0) revert ZeroAmount();
    }

    function _withdraw(NativeWithdrawData memory withdraw_) internal virtual {
        if (withdraw_.amount == 0) revert ZeroAmount();
        if (withdraw_.receiver == address(0)) revert ZeroReceiver();

        payable(withdraw_.receiver).sendValue(withdraw_.amount);
    }
}
