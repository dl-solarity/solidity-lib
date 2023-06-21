// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMultiOwnable {  

    event OwnershipAdded(address[] indexed newOwners);
    event OwnershipRemoved(address[] indexed removedOwners); 
   
    /**
    * @notice Owner can add new owners to the _owners.
    * @param newOwners_ the array of addresses to add to _owners
    */
    function addOwners(address[] memory newOwners_) external;

    /**
    * @notice Owner can remove the array of owners from the _owners.
    * @param oldOwners_ the array of addresses to remove from _owners
    */
    function removeOwners(address[] memory oldOwners_) external;

    /**
     * @notice Allows to remove yourself from list of owners. 
     * Note: number of Owners must be more than 1.
     */
    function renounceOwnership() external;  

    /**
     * @notice Returns the addresses of the current owners.
     * @dev Returns a copy of the whole Set of owners.
     * @return the array of addresses.
     */
    function getOwners() external view returns (address[] memory);
    
    /**
     * @notice Returns true if address is in _owners.
     * @param address_ the address to check.
     * @return whether the _address in _owners.
     */
    function isOwner(address address_) external view returns (bool);
}
