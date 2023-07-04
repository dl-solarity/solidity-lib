// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SBT} from "./../../tokens/SBT.sol";

contract OwnableSBT is SBT, Ownable {
    uint256 internal _tokenIdCounter;

    mapping(address => bool) internal availableToClaim;

    function __OwnableSBT_init(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) public initializer {
        __SBT_init(name_, symbol_, uri_);
        availableToClaim[msg.sender] = true;
    }

    function mint() public {
        require(availableToClaim[msg.sender], "OwnableSBT: not available to claim");

        availableToClaim[msg.sender] = false;

        _mint(msg.sender, _tokenIdCounter, _basetokenURI);

        _tokenIdCounter += 1;
    }

    function burn(uint256 tokenId_) public {
        require(_ownerOf(tokenId_) == msg.sender, "OwnableSBT: can't burn another user's nft");
        _burn(tokenId_);
    }

    function addToAvailable(address address_) public onlyOwner {
        availableToClaim[address_] = true;
    }

    function deleteFromAvailable(address address_) public onlyOwner {
        availableToClaim[address_] = false;
    }

    function setBaseTokenURI(string memory tokenURI_) public onlyOwner {
        _basetokenURI = tokenURI_;
    }
}
