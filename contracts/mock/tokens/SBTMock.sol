// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SBT} from "./../../tokens/SBT.sol";

contract SBTMock is SBT {
    function __SBTMock_init(string calldata name_, string calldata symbol_) external initializer {
        __SBT_init(name_, symbol_);
    }

    function mockInit(string calldata name_, string calldata symbol_) external {
        __SBT_init(name_, symbol_);
    }

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external {
        _burn(tokenId_);
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external {
        _setTokenURI(tokenId_, tokenURI_);
    }

    function setBaseURI(string calldata baseTokenURI_) external {
        _setBaseURI(baseTokenURI_);
    }
}
