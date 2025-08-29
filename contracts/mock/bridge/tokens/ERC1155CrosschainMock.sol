// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155URIStorage} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import {IERC1155Crosschain} from "../../../interfaces/bridge/tokens/IERC1155Crosschain.sol";

contract ERC1155CrosschainMock is IERC1155Crosschain, ERC1155Supply, ERC1155URIStorage {
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;

        _setBaseURI(uri_);
    }

    function crosschainMint(
        address receiver_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external {
        _mint(receiver_, tokenId_, amount_, "");

        if (bytes(tokenURI_).length > 0) {
            _setURI(tokenId_, tokenURI_);
        }
    }

    function crosschainBurn(address payer_, uint256 tokenId_, uint256 amount_) external {
        if (!isApprovedForAll(payer_, msg.sender)) revert ERC1155InvalidApprover(msg.sender);

        _burn(payer_, tokenId_, amount_);
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155URIStorage, ERC1155) returns (string memory) {
        return super.uri(tokenId);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._update(from, to, ids, values);
    }
}
