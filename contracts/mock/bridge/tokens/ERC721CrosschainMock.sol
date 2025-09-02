// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC721Crosschain} from "../../../interfaces/bridge/tokens/IERC721Crosschain.sol";

contract ERC721CrosschainMock is IERC721Crosschain, ERC721Enumerable, ERC721URIStorage {
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function crosschainMint(address to_, uint256 tokenId_, string calldata tokenURI_) external {
        _mint(to_, tokenId_);

        if (bytes(tokenURI_).length > 0) {
            _setTokenURI(tokenId_, tokenURI_);
        }
    }

    function crosschainBurn(address from_, uint256 tokenId_) external {
        if (
            ownerOf(tokenId_) != from_ ||
            (getApproved(tokenId_) != msg.sender && !isApprovedForAll(from_, msg.sender))
        ) revert ERC721InvalidApprover(msg.sender);

        _burn(tokenId_);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC721URIStorage, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable, ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 amount
    ) internal override(ERC721Enumerable, ERC721) {
        super._increaseBalance(account, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
