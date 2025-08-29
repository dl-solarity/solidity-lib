// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Crosschain is IERC1155 {
    function crosschainMint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external;

    function crosschainBurn(address from_, uint256 tokenId_, uint256 amount_) external;
}
