// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ISBT} from "../interfaces/tokens/ISBT.sol";

/**
 * @notice The SBT module
 *
 * An abstract lightweight implementation of a Soul Bound Token. Does not comply with ERC721 standard.
 * Approve and transfer functionality has been removed as it is not needed in SBTs.
 *
 * The contract is compatible with Metamask and Opensea.
 */
abstract contract ASBT is ISBT, ERC165Upgradeable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct ASBTStorage {
        string name;
        string symbol;
        mapping(uint256 tokenId => address owner) tokenOwners;
        mapping(address owner => EnumerableSet.UintSet balances) balances;
        string baseURI;
        mapping(uint256 tokenId => string tokenURI) tokenURIs;
    }

    // bytes32(uint256(keccak256("solarity.contract.ASBT")) - 1)
    bytes32 private constant A_SBT_STORAGE =
        0x5a40b9c2fd292e4e0de2167f20d990524d7ad1b1bbf797f218a97c33c5ea76fb;

    error ReceiverIsZeroAddress();
    error TokenAlreadyExists(uint256 tokenId);
    error TokenDoesNotExist(uint256 tokenId);

    /**
     * @notice The constructor
     * @param name_ the name of the contract (can't be changed)
     * @param symbol_ the symbol of the contract (can't be changed)
     */
    function __ASBT_init(string memory name_, string memory symbol_) internal onlyInitializing {
        ASBTStorage storage $ = _getASBTStorage();

        $.name = name_;
        $.symbol = symbol_;
    }

    /**
     * @notice The function to return the name of the contract
     * @return the name of the contract
     */
    function name() public view virtual override returns (string memory) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.name;
    }

    /**
     * @notice The function to return the symbol of the contract
     * @return the symbol of the contract
     */
    function symbol() public view virtual override returns (string memory) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.symbol;
    }

    /**
     * @notice The function to check the existence of the token
     * @param tokenId_ the token to check
     * @return true if `tokenId_` exists, false otherwise
     */
    function tokenExists(uint256 tokenId_) public view virtual override returns (bool) {
        return _ownerOf(tokenId_) != address(0);
    }

    /**
     * @notice The function to get the balance of the user
     * @param owner_ the user to get the balance of
     * @return the user's balance
     */
    function balanceOf(address owner_) public view virtual override returns (uint256) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.balances[owner_].length();
    }

    /**
     * @notice The function to get a user's token by its ordinal id
     * @param owner_ the user to get the token of
     * @param index_ the id of the token in the user's array
     * @return the token the user owns
     */
    function tokenOf(
        address owner_,
        uint256 index_
    ) public view virtual override returns (uint256) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.balances[owner_].at(index_);
    }

    /**
     * @notice The function to get ALL the tokens of a user. Be careful, O(n) complexity
     * @param owner_ the user to get the tokens of
     * @return the array of tokens the user owns
     */
    function tokensOf(address owner_) public view virtual override returns (uint256[] memory) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.balances[owner_].values();
    }

    /**
     * @notice The function to get the owner of a token
     * @param tokenId_ the token to get the owner of
     * @return address of an owner or `address(0)` if token does not exist
     */
    function ownerOf(uint256 tokenId_) public view virtual override returns (address) {
        return _ownerOf(tokenId_);
    }

    /**
     * @notice The function to get the base URI of all the tokens
     * @return the base URI
     */
    function baseURI() public view virtual override returns (string memory) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.baseURI;
    }

    /**
     * @notice The function to get the token URI.
     *
     * - If individual token URI is set, it gets returned.
     * - Otherwise if base URI is set, the concatenation of base URI and token URI gets returned.
     * - Otherwise `""` gets returned
     *
     * @param tokenId_ the token to get the URI of
     * @return the URI of the token
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        ASBTStorage storage $ = _getASBTStorage();

        string memory tokenURI_ = $.tokenURIs[tokenId_];

        if (bytes(tokenURI_).length != 0) {
            return tokenURI_;
        }

        string memory base_ = baseURI();

        if (bytes(base_).length != 0) {
            return string(abi.encodePacked(base_, tokenId_.toString()));
        }

        return "";
    }

    /**
     * @notice Returns true if this contract implements the interface defined by `interfaceId`
     * @param interfaceId_ the interface ID to check
     * @return true if the passed interface ID is supported, otherwise false
     */
    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return
            interfaceId_ == type(IERC721Metadata).interfaceId ||
            interfaceId_ == type(ISBT).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /**
     * @notice The function to mint the token
     * @param to_ the receiver of the token
     * @param tokenId_ the token to mint
     */
    function _mint(address to_, uint256 tokenId_) internal virtual {
        if (to_ == address(0)) revert ReceiverIsZeroAddress();
        if (tokenExists(tokenId_)) revert TokenAlreadyExists(tokenId_);

        _beforeTokenAction(to_, tokenId_);

        ASBTStorage storage $ = _getASBTStorage();

        $.balances[to_].add(tokenId_);
        $.tokenOwners[tokenId_] = to_;

        emit Transfer(address(0), to_, tokenId_);
    }

    /**
     * @notice The function to burn the token
     * @param tokenId_ the token to burn
     */
    function _burn(uint256 tokenId_) internal virtual {
        address owner_ = _ownerOf(tokenId_);

        if (owner_ == address(0)) revert TokenDoesNotExist(tokenId_);

        _beforeTokenAction(address(0), tokenId_);

        ASBTStorage storage $ = _getASBTStorage();

        $.balances[owner_].remove(tokenId_);
        delete $.tokenOwners[tokenId_];

        delete $.tokenURIs[tokenId_];

        emit Transfer(owner_, address(0), tokenId_);
    }

    /**
     * @notice The function to set the individual token URI
     * @param tokenId_ the token to set the URI of
     * @param tokenURI_ the URI to be set
     */
    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal virtual {
        if (!tokenExists(tokenId_)) revert TokenDoesNotExist(tokenId_);

        ASBTStorage storage $ = _getASBTStorage();

        $.tokenURIs[tokenId_] = tokenURI_;
    }

    /**
     * @notice The function to set the base URI of all the tokens
     * @param baseURI_ the URI to set
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        ASBTStorage storage $ = _getASBTStorage();

        $.baseURI = baseURI_;
    }

    /**
     * @notice The function to get the owner of a token
     * @param tokenId_ the token to get the owner of
     * @return address of an owner or `address(0)` if token does not exist
     */
    function _ownerOf(uint256 tokenId_) internal view virtual returns (address) {
        ASBTStorage storage $ = _getASBTStorage();

        return $.tokenOwners[tokenId_];
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getASBTStorage() private pure returns (ASBTStorage storage $) {
        assembly {
            $.slot := A_SBT_STORAGE
        }
    }

    /**
     * @notice The hook that is called before the `mint` and `burn` actions occur
     * @param to_ the receiver address if `mint` and `address(0)` if burn
     * @param tokenId_ the token used in the action
     */
    function _beforeTokenAction(address to_, uint256 tokenId_) internal virtual {}
}
