// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ISBT} from "../interfaces/tokens/ISBT.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract SBT is ISBT, Initializable {
    using Strings for uint256;

    string internal _baseTokenURI;
    string private _name;
    string private _symbol;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;

    function __SBT_init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI_;
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

    function baseURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        if (bytes(_tokenURIs[tokenId_]).length != 0) {
            return _tokenURIs[tokenId_];
        }

        string memory base_ = baseURI();

        return
            bytes(base_).length != 0 ? string(abi.encodePacked(base_, tokenId_.toString())) : "";
    }

    function isTokenExist(uint256 tokenId_) public view override returns (bool) {
        return _ownerOf(tokenId_) != address(0);
    }

    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0), "SBT: invalidReceiver(address(0)");

        require(!isTokenExist(tokenId_), "SBT: already exist tokenId");

        unchecked {
            _balances[to_] += 1;
        }

        _tokenOwners[tokenId_] = to_;

        emit Minted(to_, tokenId_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        address owner_ = _ownerOf(tokenId_);

        require(owner_ != address(0), "SBT: sbt you want to burn don't exist");

        unchecked {
            _balances[owner_] -= 1;
        }

        delete _tokenOwners[tokenId_];

        emit Burned(owner_, tokenId_);
    }

    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal virtual {
        require(isTokenExist(tokenId_), "SBT: nonexistent tokenId");

        _tokenURIs[tokenId_] = tokenURI_;
    }

    function _ownerOf(uint256 tokenId_) internal view virtual returns (address) {
        return _tokenOwners[tokenId_];
    }
}
