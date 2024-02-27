// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DiamondOwnableStorage} from "./DiamondOwnableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's Ownable contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondOwnable is DiamondOwnableStorage {
    /**
     * @notice Transfers ownership to `msg.sender`
     */
    function __DiamondOwnable_init() internal onlyInitializing(DIAMOND_OWNABLE_STORAGE_SLOT) {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice The function to transfer the Diamond ownership
     * @param newOwner_ the new owner of the Diamond
     */
    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "DiamondOwnable: zero address owner");

        _transferOwnership(newOwner_);
    }

    /**
     * @notice The function to leave Diamond without an owner
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice The function to appoint a new Diamond owner
     */
    function _transferOwnership(address newOwner_) internal {
        _getDiamondOwnableStorage().owner = newOwner_;
    }
}
