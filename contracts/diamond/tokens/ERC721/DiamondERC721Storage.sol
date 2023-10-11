// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {DiamondERC165} from "../../introspection/DiamondERC165.sol";
import {InitializableStorage} from "../../utils/InitializableStorage.sol";

/**
 * @notice This is an ERC721 token Storage contract with Diamond Standard support
 */
abstract contract DiamondERC721Storage is
    Context,
    InitializableStorage,
    DiamondERC165,
    IERC721,
    IERC721Metadata
{
    using Strings for uint256;

    bytes32 public constant DIAMOND_ERC721_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.erc721.storage");

    struct DERC721Storage {
        string name;
        string symbol;
        mapping(uint256 => address) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function _getErc721Storage() internal pure returns (DERC721Storage storage _erc721Storage) {
        bytes32 slot_ = DIAMOND_ERC721_STORAGE_SLOT;

        assembly {
            _erc721Storage.slot := slot_
        }
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(DiamondERC165, IERC165) returns (bool) {
        return
            interfaceId_ == type(IERC721).interfaceId ||
            interfaceId_ == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() public view virtual override returns (string memory) {
        return _getErc721Storage().name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() public view virtual override returns (string memory) {
        return _getErc721Storage().symbol;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId_.toString()))
                : "";
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address owner_) public view virtual override returns (uint256) {
        return _getErc721Storage().balances[owner_];
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId_) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId_);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);

        return _getErc721Storage().tokenApprovals[tokenId_];
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address owner_,
        address operator_
    ) public view virtual override returns (bool) {
        return _getErc721Storage().operatorApprovals[owner_][operator_];
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "ERC721: invalid token ID");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _ownerOf(tokenId_) != address(0);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId_) internal view virtual returns (address) {
        return _getErc721Storage().owners[tokenId_];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }
}
