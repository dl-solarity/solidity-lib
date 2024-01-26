// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "../../Diamond.sol";
import {OwnableDiamondStorage} from "./OwnableDiamondStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * The Ownable preset of Diamond proxy
 */
contract OwnableDiamond is Diamond, OwnableDiamondStorage {
    constructor() {
        transferOwnership(msg.sender);
    }

    /**
     * @notice The function to transfer the Diamond ownerhip
     * @param newOwner_ the new owner of the Diamond
     */
    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "OwnableDiamond: zero address owner");

        _getOwnableDiamondStorage().owner = newOwner_;
    }

    /**
     * @notice The function to manipulate the Diamond contract, as defined in [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
     * @param facets_ the array of actions to be executed against the Diamond
     */
    function diamondCut(Facet[] memory facets_) public onlyOwner {
        diamondCut(facets_, address(0), "");
    }

    /**
     * @notice The function to manipulate the Diamond contract, as defined in [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
     * @param facets_ the array of actions to be executed against the Diamond
     * @param init_ the address of the init contract to be called via delegatecall
     * @param initData_ the data the init address will be called with
     */
    function diamondCut(
        Facet[] memory facets_,
        address init_,
        bytes memory initData_
    ) public onlyOwner {
        _diamondCut(facets_, init_, initData_);
    }
}
