// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {DiamondERC721} from "../../../diamond/tokens/ERC721/DiamondERC721.sol";

contract DiamondERC721Mock is DiamondERC721 {
    string baseUri;
    bool replaceOwner;

    constructor() {
        _disableInitializers(DIAMOND_ERC721_STORAGE_SLOT);
    }

    function __DiamondERC721Direct_init(string memory name_, string memory symbol_) external {
        __DiamondERC721_init(name_, symbol_);
    }

    function __DiamondERC721Mock_init(
        string memory name_,
        string memory symbol_
    ) external initializer(DIAMOND_ERC721_STORAGE_SLOT) {
        __DiamondERC721_init(name_, symbol_);
    }

    function toggleReplaceOwner() external {
        replaceOwner = !replaceOwner;
    }

    function setBaseURI(string memory baseUri_) external {
        baseUri = baseUri_;
    }

    function mint(address to_, uint256 tokenId_) external {
        _safeMint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external {
        _burn(tokenId_);
    }

    function transferFromMock(address from_, address to_, uint256 tokenId_) external {
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFromMock(address from_, address to_, uint256 tokenId_) external {
        safeTransferFrom(from_, to_, tokenId_);
    }

    function beforeTokenTransfer(uint256 batchSize) external {
        _beforeTokenTransfer(address(this), address(this), 1, batchSize);
    }

    function disableInitializers() external {
        _disableInitializers(DIAMOND_ERC721_STORAGE_SLOT);
    }

    function _baseURI() internal view override returns (string memory) {
        super._baseURI();
        return baseUri;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal override {
        if (replaceOwner) {
            _getErc721Storage().owners[firstTokenId_] = address(this);
        } else {
            super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
        }
    }
}

contract NonERC721Receiver is IERC721Receiver {
    error RevertingOnERC721Received();

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert RevertingOnERC721Received();
    }
}
