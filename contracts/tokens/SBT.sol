// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ISBT} from "../interfaces/tokens/ISBT.sol";

/**
 * @notice The SBT module
 *
 * Am abstract lightweight implementation of a Soul Bound Token. Does not comply with ERC721 standard.
 * Approve and transfer functionality has been removed as it is not needed in SBTs.
 *
 * Has to be inherited in order to be useful in the project
 */
abstract contract SBT is ISBT, Initializable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _tokenOwners;
    mapping(address => EnumerableSet.UintSet) private _balances;

    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @notice The constructor
     * @param name_ the name of the contract (can't be changed)
     * @param symbol_ the symbol of the contract (can't be changed)
     */
    function __SBT_init(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice The function to return the name of the contract
     * @return the name of the contract
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice The function to return the symbol of the contract
     * @return the symbol of the contract
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice The function to check the existence of the token
     * @param tokenId_ the token to check
     * @return true if `tokenId_` exists, false otherwise
     */
    function tokenExists(uint256 tokenId_) public view override returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    /**
     * @notice The function to get the balance of the user
     * @param owner_ the user to get the balance of
     * @return the user's balance
     */
    function balanceOf(address owner_) public view override returns (uint256) {
        return _balances[owner_].length();
    }

    /**
     * @notice The function to get a user's token by its ordinal id
     * @param owner_ the user to get the token of
     * @param index_ the id of the token in the user's array
     */
    function tokenOf(address owner_, uint256 index_) public view override returns (uint256) {
        return _balances[owner_].at(index_);
    }

    /**
     * @notice The function to get ALL the tokens of a user. Be careful, O(n) complexity
     * @param owner_ the user to get the tokens of
     * @return the array of tokens the user owns
     */
    function tokensOf(address owner_) public view override returns (uint256[] memory) {
        return _balances[owner_].values();
    }

    /**
     * @notice The function to get the owner of a token
     * @param tokenId_ the token to get the owner of
     * @return address of an owner or `address(0)` if token does not exist
     */
    function ownerOf(uint256 tokenId_) public view override returns (address) {
        return _tokenOwners[tokenId_];
    }

    /**
     * @notice The function to get the base URI of all the tokens
     * @return the base URI
     */
    function baseURI() public view virtual override returns (string memory) {
        return _baseURI;
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
        if (bytes(_tokenURIs[tokenId_]).length != 0) {
            return _tokenURIs[tokenId_];
        }

        string memory base_ = baseURI();

        return
            bytes(base_).length != 0 ? string(abi.encodePacked(base_, tokenId_.toString())) : "";
    }

    /**
     * @notice The function to mint the token
     * @param to_ the receiver of the token
     * @param tokenId_ the token to mint
     */
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0), "SBT: address(0) receiver");
        require(!tokenExists(tokenId_), "SBT: token already exists");

        _beforeTokenAction(to_, tokenId_);

        _balances[to_].add(tokenId_);
        _tokenOwners[tokenId_] = to_;

        emit Minted(to_, tokenId_);
    }

    /**
     * @notice The function to burn the token
     * @param tokenId_ the token to burn
     */
    function _burn(uint256 tokenId_) internal virtual {
        address owner_ = ownerOf(tokenId_);
        require(owner_ != address(0), "SBT: token doesn't exist");

        _beforeTokenAction(address(0), tokenId_);

        _balances[owner_].remove(tokenId_);
        delete _tokenOwners[tokenId_];

        delete _tokenURIs[tokenId_];

        emit Burned(owner_, tokenId_);
    }

    /**
     * @notice The function to set the individual token URI
     * @param tokenId_ the token to set the URI of
     * @param tokenURI_ the URI to be set
     */
    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal virtual {
        require(tokenExists(tokenId_), "SBT: token doesn't exist");

        _tokenURIs[tokenId_] = tokenURI_;
    }

    /**
     * @notice The function to set the base URI of all the tokens
     * @param baseURI_ the URI to set
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @notice The hook that is called before the `mint` and `burn` actions occur
     * @param to_ the receiver address if `mint` and `address(0)` if burn
     * @param tokenId_ the token used in the action
     */
    function _beforeTokenAction(address to_, uint256 tokenId_) internal virtual {}
}
