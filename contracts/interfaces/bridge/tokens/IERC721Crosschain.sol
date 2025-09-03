// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Crosschain is IERC721 {
    function crosschainMint(address to_, uint256 tokenId_, string calldata tokenURI_) external;

    function crosschainBurn(address from_, uint256 tokenId_) external;
}
