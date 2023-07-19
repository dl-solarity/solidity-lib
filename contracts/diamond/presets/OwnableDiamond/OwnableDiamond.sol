// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "../../Diamond.sol";
import {OwnableDiamondStorage} from "./OwnableDiamondStorage.sol";

/**
 * @notice The Ownable preset of Diamond proxy
 */
contract OwnableDiamond is Diamond, OwnableDiamondStorage {
    constructor() {
        transferOwnership(msg.sender);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "OwnableDiamond: zero address owner");

        _getOwnableDiamondStorage().owner = newOwner_;
    }

    function addFacet(address facet_, bytes4[] memory selectors_) public virtual onlyOwner {
        _addFacet(facet_, selectors_);
    }

    function removeFacet(address facet_, bytes4[] memory selectors_) public virtual onlyOwner {
        _removeFacet(facet_, selectors_);
    }

    function updateFacet(
        address facet_,
        bytes4[] memory fromSelectors_,
        bytes4[] memory toSelectors_
    ) public virtual onlyOwner {
        _updateFacet(facet_, fromSelectors_, toSelectors_);
    }
}
