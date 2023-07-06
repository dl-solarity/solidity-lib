// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableSBT} from "./../../tokens/presets/OwnableSBT.sol";

contract SBTMock is OwnableSBT {
    function mockInit(
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
}
