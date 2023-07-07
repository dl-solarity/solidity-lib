// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SBT} from "./../../tokens/SBT.sol";

contract WhitelistedSBT is SBT {
    mapping(address => bool) internal _whitelisted;

    function __WhitelistedSBT_init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI_,
        address[] calldata addresses_
    ) internal onlyInitializing {
        __SBT_init(name_, symbol_, baseTokenURI_);
        _addToWhitelist(addresses_);
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return _whitelisted[address_];
    }

    function _mint(address to_, uint256 tokenId_) internal virtual override {
        require(isWhitelisted(msg.sender), "WhitelistedSBT: not available to claim");
        super._mint(to_, tokenId_);
    }

    function _addToWhitelist(address[] memory addresses_) internal virtual {
        for (uint i = 0; i < addresses_.length; i++) {
            _whitelisted[addresses_[i]] = true;
        }
    }

    function _deleteFromWhitelist(address[] memory addresses_) internal virtual {
        for (uint i = 0; i < addresses_.length; i++) {
            _whitelisted[addresses_[i]] = false;
        }
    }
}
