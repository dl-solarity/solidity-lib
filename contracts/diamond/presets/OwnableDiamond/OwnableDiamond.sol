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

    function diamondCut(Facet[] memory facets_) public virtual onlyOwner {
        _diamondCut(facets_);
    }

    function diamondCut(
        Facet[] memory facets_,
        address init_,
        bytes memory calldata_
    ) public virtual onlyOwner {
        _diamondCut(facets_, init_, calldata_);
    }
}
