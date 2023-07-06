// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SBT} from "./../../tokens/SBT.sol";

contract OwnableSBT is SBT, Ownable {
    uint256 internal _tokenIdCounter;

    mapping(address => bool) internal availableToClaim;

    function __OwnableSBT_init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI_
    ) public initializer {
        __SBT_init(name_, symbol_, baseTokenURI_);
    }

    function mint() public {
        require(availableToClaim[msg.sender], "OwnableSBT: not available to claim");

        availableToClaim[msg.sender] = false;

        _mint(msg.sender, _tokenIdCounter);

        _setTokenURI(_tokenIdCounter, tokenURI(_tokenIdCounter));

        _tokenIdCounter += 1;
    }

    function burn(uint256 tokenId_) public {
        require(_ownerOf(tokenId_) == msg.sender, "OwnableSBT: can't burn another user's nft");
        _burn(tokenId_);
    }

    function addToAvailable(address[] memory addresses_) public onlyOwner {
        for (uint i = 0; i < addresses_.length; i++) {
            availableToClaim[addresses_[i]] = true;
        }
    }

    function deleteFromAvailable(address[] memory addresses_) public onlyOwner {
        for (uint i = 0; i < addresses_.length; i++) {
            availableToClaim[addresses_[i]] = false;
        }
    }

    function ifAvailable(address address_) public view returns (bool) {
        return availableToClaim[address_];
    }

    function setBaseTokenURI(string memory tokenURI_) external onlyOwner {
        _baseTokenURI = tokenURI_;
    }
    
    function getBaseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}
