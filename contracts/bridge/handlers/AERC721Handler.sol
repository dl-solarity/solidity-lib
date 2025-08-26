// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {IBridge} from "../../interfaces/bridge/IBridge.sol";
import {IERC721Crosschain} from "../../interfaces/bridge/tokens/IERC721Crosschain.sol";

/**
 * @title ERC721Handler
 */
abstract contract AERC721Handler is ERC721Holder {
    function _depositERC721(
        address token_,
        uint256 tokenId_,
        IBridge.ERC721BridgingType operationType_
    ) internal virtual {
        if (token_ == address(0)) revert IBridge.InvalidToken();

        IERC721Crosschain erc721_ = IERC721Crosschain(token_);

        if (operationType_ == IBridge.ERC721BridgingType.Wrapped) {
            erc721_.crosschainBurn(msg.sender, tokenId_);
        } else {
            erc721_.safeTransferFrom(msg.sender, address(this), tokenId_);
        }
    }

    function _withdrawERC721(
        address token_,
        uint256 tokenId_,
        address receiver_,
        string calldata tokenURI_,
        IBridge.ERC721BridgingType operationType_
    ) internal virtual {
        if (token_ == address(0)) revert IBridge.InvalidToken();
        if (receiver_ == address(0)) revert IBridge.InvalidReceiver();

        IERC721Crosschain erc721_ = IERC721Crosschain(token_);

        if (operationType_ == IBridge.ERC721BridgingType.Wrapped) {
            erc721_.crosschainMint(receiver_, tokenId_, tokenURI_);
        } else {
            erc721_.safeTransferFrom(address(this), receiver_, tokenId_);
        }
    }

    function getERC721SignHash(
        address token_,
        uint256 tokenId_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        uint256 chainId_,
        string calldata tokenURI_,
        IBridge.ERC721BridgingType operationType_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    token_,
                    tokenId_,
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
