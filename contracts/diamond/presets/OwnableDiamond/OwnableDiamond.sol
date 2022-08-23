// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../Diamond.sol";
import "./OwnableDiamondStorage.sol";

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
}