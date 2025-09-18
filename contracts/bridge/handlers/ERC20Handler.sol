// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";
import {IHandler} from "../../interfaces/bridge/IHandler.sol";
import {IUSDCCrosschain} from "../../interfaces/bridge/tokens/IUSDCCrosschain.sol";
import {IERC20Crosschain} from "../../interfaces/bridge/tokens/IERC20Crosschain.sol";

/**
 * @title ERC20Handler
 *
 * The handler supports both "liquidity pool" and "mint-and-burn" methods for managing assets.
 * If "mint-and-burn" method is used, the ERC-20 tokens are required to support ERC-7802 interface.
 *
 * The handler is also suitable for bridged USDC tokens, utilizing their interface
 * (https://github.com/circlefin/stablecoin-evm/blob/master/doc/bridged_USDC_standard.md).
 */
contract ERC20Handler is IHandler {
    using SafeERC20 for IERC20Crosschain;

    enum ERC20BridgingType {
        LiquidityPool,
        Wrapped,
        USDCType
    }

    event DispatchedERC20(
        address token,
        uint256 amount,
        string receiver,
        string network,
        bytes batch,
        ERC20BridgingType operationType
    );

    struct ERC20DispatchData {
        address token;
        uint256 amount;
        string receiver;
        string network;
        bytes batch;
        ERC20BridgingType operationType;
    }

    /**
     * @dev Nonce is computed as keccak256(abi.encodePacked(originNetworkName, originTxHash, eventNumber)).
     */
    struct ERC20RedeemData {
        address token;
        uint256 amount;
        address receiver;
        bytes batch;
        ERC20BridgingType operationType;
        bytes32 nonce;
    }

    /**
     * @inheritdoc IHandler
     */
    function dispatch(bytes calldata dispatchDetails_) external payable virtual {
        ERC20DispatchData memory dispatch_ = abi.decode(dispatchDetails_, (ERC20DispatchData));

        _dispatch(dispatch_);

        emit DispatchedERC20(
            dispatch_.token,
            dispatch_.amount,
            dispatch_.receiver,
            dispatch_.network,
            dispatch_.batch,
            dispatch_.operationType
        );
    }

    /**
     * @inheritdoc IHandler
     */
    function redeem(IBatcher batcher_, bytes calldata redeemDetails_) external virtual {
        ERC20RedeemData memory redeem_ = abi.decode(redeemDetails_, (ERC20RedeemData));

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
        ERC20RedeemData memory redeem_ = abi.decode(redeemDetails_, (ERC20RedeemData));

        return
            keccak256(
                abi.encodePacked(
                    redeem_.token,
                    redeem_.amount,
                    redeem_.receiver,
                    redeem_.batch,
                    redeem_.operationType,
                    redeem_.nonce,
                    network_,
                    address(this)
                )
            );
    }

    function _dispatch(ERC20DispatchData memory dispatch_) internal virtual {
        if (dispatch_.token == address(0)) revert ZeroToken();
        if (dispatch_.amount == 0) revert ZeroAmount();

        IERC20Crosschain erc20_ = IERC20Crosschain(dispatch_.token);

        if (dispatch_.operationType == ERC20BridgingType.Wrapped) {
            erc20_.crosschainBurn(msg.sender, dispatch_.amount);
        } else {
            erc20_.safeTransferFrom(msg.sender, address(this), dispatch_.amount);
        }

        // USDC-specific logic: first transferFrom, then burn
        if (dispatch_.operationType == ERC20BridgingType.USDCType) {
            IUSDCCrosschain(dispatch_.token).burn(dispatch_.amount);
        }
    }

    function _redeem(ERC20RedeemData memory redeem_) internal virtual {
        if (redeem_.token == address(0)) revert ZeroToken();
        if (redeem_.amount == 0) revert ZeroAmount();
        if (redeem_.receiver == address(0)) revert ZeroReceiver();

        IERC20Crosschain erc20_ = IERC20Crosschain(redeem_.token);

        if (redeem_.operationType == ERC20BridgingType.Wrapped) {
            erc20_.crosschainMint(redeem_.receiver, redeem_.amount);
        } else if (redeem_.operationType == ERC20BridgingType.USDCType) {
            IUSDCCrosschain(redeem_.token).mint(redeem_.receiver, redeem_.amount);
        } else {
            erc20_.safeTransfer(redeem_.receiver, redeem_.amount);
        }
    }
}
