// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ISBT} from "../interfaces/tokens/ISBT.sol";

abstract contract SBT is ISBT, Initializable {
    string internal _basetokenURI;
    string private _name;
    string private _symbol;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) private _tokenOwners;

    mapping(address => uint256) private _balances;

    function __SBT_init(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _basetokenURI = uri_;
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId_) public view override returns (address) {
        return _ownerOf(tokenId_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId_];
    }

    function ifTokenExist(uint256 tokenId_) public view override returns (bool) {
        if (_ownerOf(tokenId_) != address(0)) return true;
        else return false;
    }

    function _mint(address to_, uint256 tokenId_, string memory tokenURI_) internal {
        require(to_ != address(0), "SBT: invalidReceiver(address(0)");

        require(_ownerOf(tokenId_) == address(0), "SBT: already exist tokenId");

        unchecked {
            _balances[to_] += 1;
        }

        _tokenOwners[tokenId_] = to_;

        string memory empty = "";
        if (keccak256(bytes(tokenURI_)) != keccak256(bytes(empty)))
            _setTokenURI(tokenId_, tokenURI_);

        emit Minted(to_, tokenId_);
    }

    function _burn(uint256 tokenId_) internal {
        address owner_ = _ownerOf(tokenId_);

        require(owner_ != address(0), "SBT: no owner for sbt you want to burn");

        _balances[owner_] -= 1;

        delete _tokenOwners[tokenId_];

        emit Burned(owner_, tokenId_);
    }

    /**
     * @notice Sets URI for particular token
     * @dev Internal function without access restriction.
     * @param tokenId_ number of a token to change URI
     * @param tokenURI_ URI to set for sbt
     */
    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal virtual {
        require(_ownerOf(tokenId_) != address(0), "SBT: nonexistent tokenId");

        _tokenURIs[tokenId_] = tokenURI_;
    }

    function _ownerOf(uint256 tokenId_) internal view virtual returns (address) {
        return _tokenOwners[tokenId_];
    }
}
