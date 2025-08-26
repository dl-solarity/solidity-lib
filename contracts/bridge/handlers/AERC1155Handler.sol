// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IBridge} from "../../interfaces/bridge/IBridge.sol";
import {IERC1155Crosschain} from "../../interfaces/bridge/tokens/IERC1155Crosschain.sol";

/**
 * @title ERC1155Handler
 */
abstract contract AERC1155Handler is ERC1155Holder {
    function _depositERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        IBridge.ERC1155BridgingType operationType_
    ) internal virtual {
        require(token_ != address(0), "ERC1155Handler: zero token");
        require(amount_ > 0, "ERC1155Handler: amount is zero");

        IERC1155Crosschain erc1155_ = IERC1155Crosschain(token_);

        if (operationType_ == IBridge.ERC1155BridgingType.Wrapped) {
            erc1155_.crosschainBurn(msg.sender, tokenId_, amount_);
        } else {
            erc1155_.safeTransferFrom(msg.sender, address(this), tokenId_, amount_, "");
        }
    }

    function _withdrawERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        address receiver_,
        string calldata tokenURI_,
        IBridge.ERC1155BridgingType operationType_
    ) internal virtual {
        require(token_ != address(0), "ERC1155Handler: zero token");
        require(receiver_ != address(0), "ERC1155Handler: zero receiver");
        require(amount_ > 0, "ERC1155Handler: amount is zero");

        IERC1155Crosschain erc1155_ = IERC1155Crosschain(token_);

        if (operationType_ == IBridge.ERC1155BridgingType.Wrapped) {
            erc1155_.crosschainMint(receiver_, tokenId_, amount_, tokenURI_);
        } else {
            erc1155_.safeTransferFrom(address(this), receiver_, tokenId_, amount_, "");
        }
    }

    function getERC1155SignHash(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        uint256 chainId_,
        string calldata tokenURI_,
        IBridge.ERC1155BridgingType operationType_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    token_,
                    tokenId_,
                    amount_,
                    receiver_,
                    txHash_,
                    txNonce_,
                    chainId_,
                    tokenURI_,
                    operationType_
                )
            );
    }
}
