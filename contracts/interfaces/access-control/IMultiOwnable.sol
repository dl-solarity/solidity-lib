// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The MultiOwnable module
 */
interface IMultiOwnable {
    event OwnersAdded(address[] newOwners);
    event OwnersRemoved(address[] removedOwners);

    /**
     * @notice Owner can add new owners to the contract's owners list.
     * @param newOwners_ the array of addresses to add to _owners.
     */
    function addOwners(address[] calldata newOwners_) external;

    /**
     * @notice Owner can remove the array of owners from the contract's owners list.
     * @param oldOwners_ the array of addresses to remove from _owners
     */
    function removeOwners(address[] calldata oldOwners_) external;

    /**
     * @notice Allows to remove yourself from list of owners.
     
     * Note: renouncing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @notice Returns the addresses of the current owners.
     * @dev Returns a copy of the whole Set of owners.
     * @return the array of addresses.
     */
    function getOwners() external view returns (address[] memory);

    /**
     * @notice Returns true if address is in the contract's owners list.
     * @param address_ the address to check.
     * @return whether the _address in _owners.
     */
    function isOwner(address address_) external view returns (bool);
}
