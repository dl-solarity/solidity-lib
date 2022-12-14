// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../Diamond.sol";
import "./OwnableDiamondStorage.sol";

/**
 *  @notice The Ownable preset of Diamond proxy
 */
contract OwnableDiamond is Diamond, OwnableDiamondStorage {
    constructor() {
        transferOwnership(msg.sender);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "OwnableDiamond: zero address owner");

        getOwnableDiamondStorage().owner = newOwner;
    }

    function addFacet(address facet, bytes4[] memory selectors) public onlyOwner {
        _addFacet(facet, selectors);
    }

    function removeFacet(address facet, bytes4[] memory selectors) public onlyOwner {
        _removeFacet(facet, selectors);
    }

    function updateFacet(
        address facet,
        bytes4[] memory fromSelectors,
        bytes4[] memory toSelectors
    ) public onlyOwner {
        _updateFacet(facet, fromSelectors, toSelectors);
    }
}
