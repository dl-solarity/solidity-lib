// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The SBT module
 */
interface ISBT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenExists(uint256 tokenId_) external view returns (bool);

    function balanceOf(address owner_) external view returns (uint256);

    function tokenOf(address owner_, uint256 index_) external view returns (uint256);

    function tokensOf(address owner_) external view returns (uint256[] memory);

    function ownerOf(uint256 tokenId_) external view returns (address);

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId_) external view returns (string memory);
}
