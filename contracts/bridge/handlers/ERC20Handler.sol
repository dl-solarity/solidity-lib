// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {IHandler} from "../../interfaces/bridge/IHandler.sol";
import {IUSDCCrosschain} from "../../interfaces/bridge/tokens/IUSDCCrosschain.sol";
import {IERC20Crosschain} from "../../interfaces/bridge/tokens/IERC20Crosschain.sol";

/**
 * @title ERC20Handler
 */
contract ERC20Handler is IHandler {
    using SafeERC20 for IERC20Crosschain;

    enum ERC20BridgingType {
        LiquidityPool,
        Wrapped,
        USDCType
    }

    event DepositedERC20(
        address token,
        uint256 amount,
        string receiver,
        string network,
        bytes batch,
        ERC20BridgingType operationType
    );

    struct ERC20DepositData {
        address token;
        uint256 amount;
        string receiver;
        string network;
        bytes batch;
        ERC20BridgingType operationType;
    }

    struct ERC20WithdrawData {
        address token;
        uint256 amount;
        address receiver;
        bytes batch;
        ERC20BridgingType operationType;
        bytes32 nonce; // keccak256(abi.encodePacked(origin network name . origin tx hash . event number))
    }

    function deposit(bytes calldata depositDetails_) external virtual {
        ERC20DepositData memory deposit_ = abi.decode(depositDetails_, (ERC20DepositData));

        _deposit(deposit_);
    }

    function withdraw(IBatcher batcher_, bytes calldata withdrawDetails_) external virtual {
        ERC20WithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (ERC20WithdrawData));

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
        ERC20WithdrawData memory withdraw_ = abi.decode(withdrawDetails_, (ERC20WithdrawData));

        return
            keccak256(
                abi.encodePacked(
                    withdraw_.token,
                    withdraw_.amount,
                    withdraw_.receiver,
                    withdraw_.batch,
                    withdraw_.operationType,
                    withdraw_.nonce,
                    network_,
                    address(this)
                )
            );
    }

    function _deposit(ERC20DepositData memory deposit_) internal virtual {
        if (deposit_.token == address(0)) revert ZeroToken();
        if (deposit_.amount == 0) revert ZeroAmount();

        IERC20Crosschain erc20_ = IERC20Crosschain(deposit_.token);

        if (deposit_.operationType == ERC20BridgingType.Wrapped) {
            erc20_.crosschainBurn(msg.sender, deposit_.amount);
        } else {
            erc20_.safeTransferFrom(msg.sender, address(this), deposit_.amount);
        }

        // USDC-specific logic: first transferFrom, then burn
        if (deposit_.operationType == ERC20BridgingType.USDCType) {
            IUSDCCrosschain(deposit_.token).burn(deposit_.amount);
        }
    }

    function _withdraw(ERC20WithdrawData memory withdraw_) internal virtual {
        if (withdraw_.token == address(0)) revert ZeroToken();
        if (withdraw_.amount == 0) revert ZeroAmount();
        if (withdraw_.receiver == address(0)) revert ZeroReceiver();

        IERC20Crosschain erc20_ = IERC20Crosschain(withdraw_.token);

        if (withdraw_.operationType == ERC20BridgingType.Wrapped) {
            erc20_.crosschainMint(withdraw_.receiver, withdraw_.amount);
        } else if (withdraw_.operationType == ERC20BridgingType.USDCType) {
            IUSDCCrosschain(withdraw_.token).mint(withdraw_.receiver, withdraw_.amount);
        } else {
            erc20_.safeTransfer(withdraw_.receiver, withdraw_.amount);
        }
    }
}
