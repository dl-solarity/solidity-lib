// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISBT {
    event Minted(address to, uint256 tokenId);
    event Burned(address from, uint256 tokenId);

    function balanceOf(address owner_) external view returns (uint256);

    function ownerOf(uint256 tokenId_) external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId_) external view returns (string memory);

    function ifTokenExist(uint256 tokenId_) external view returns (bool);
}
