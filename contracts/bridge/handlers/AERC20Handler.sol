// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBridge} from "../../interfaces/bridge/IBridge.sol";
import {IUSDCCrosschain} from "../../interfaces/bridge/tokens/IUSDCCrosschain.sol";
import {IERC20Crosschain} from "../../interfaces/bridge/tokens/IERC20Crosschain.sol";

/**
 * @title ERC20Handler
 */
abstract contract AERC20Handler {
    using SafeERC20 for IERC20Crosschain;

    function _depositERC20(
        address token_,
        uint256 amount_,
        IBridge.ERC20BridgingType operationType_
    ) internal virtual {
        require(token_ != address(0), "ERC20Handler: zero token");
        require(amount_ > 0, "ERC20Handler: amount is zero");

        IERC20Crosschain erc20_ = IERC20Crosschain(token_);

        if (operationType_ == IBridge.ERC20BridgingType.Wrapped) {
            erc20_.crosschainBurn(msg.sender, amount_);
        } else {
            erc20_.safeTransferFrom(msg.sender, address(this), amount_);
        }

        // USDC-specific logic: first transferFrom, then burn
        if (operationType_ == IBridge.ERC20BridgingType.USDCType) {
            IUSDCCrosschain(token_).burn(amount_);
        }
    }

    function _withdrawERC20(
        address token_,
        uint256 amount_,
        address receiver_,
        IBridge.ERC20BridgingType operationType_
    ) internal virtual {
        require(token_ != address(0), "ERC20Handler: zero token");
        require(amount_ > 0, "ERC20Handler: amount is zero");
        require(receiver_ != address(0), "ERC20Handler: zero receiver");

        IERC20Crosschain erc20_ = IERC20Crosschain(token_);

        if (operationType_ == IBridge.ERC20BridgingType.Wrapped) {
            erc20_.crosschainMint(receiver_, amount_);
        } else if (operationType_ == IBridge.ERC20BridgingType.USDCType) {
            IUSDCCrosschain(token_).mint(receiver_, amount_);
        } else {
            erc20_.safeTransfer(receiver_, amount_);
        }
    }

    function getERC20SignHash(
        address token_,
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        uint256 chainId_,
        IBridge.ERC20BridgingType operationType_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    token_,
                    amount_,
                    receiver_,
                    txHash_,
                    txNonce_,
                    chainId_,
                    operationType_
                )
            );
    }
}
