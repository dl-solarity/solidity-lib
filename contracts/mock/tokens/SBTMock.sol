// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {WhitelistedSBT} from "./../../tokens/extensions/WhitelistedSBT.sol";

contract SBTMock is WhitelistedSBT {
    function __WhitelistedSBTMock_init(
        string calldata name_,
        string calldata symbol_,
        string calldata uri_,
        address[] calldata addresses_
    ) external initializer {
        __WhitelistedSBT_init(name_, symbol_, uri_, addresses_);
    }

    function mockInit(
        string calldata name_,
        string calldata symbol_,
        string calldata uri_,
        address[] calldata addresses_
    ) external {
        __WhitelistedSBT_init(name_, symbol_, uri_, addresses_);
    }

    function __SBTMock_init(
        string calldata name_,
        string calldata symbol_,
        string calldata uri_
    ) external {
        __SBT_init(name_, symbol_, uri_);
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external {
        _setTokenURI(tokenId_, tokenURI_);
    }

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

    function burnMock(uint256 tokenId_) external {
        _burn(tokenId_);
    }

    function addToWhitelist(address[] memory addresses_) external {
        _addToWhitelist(addresses_);
    }

    function deleteFromWhitelist(address[] memory addresses_) external {
        _deleteFromWhitelist(addresses_);
    }

    function setBaseTokenURI(string memory baseTokenURI_) external {
        _baseTokenURI = baseTokenURI_;
    }
}
