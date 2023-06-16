// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiOwnable {  

    event OwnershipAdded(address[] indexed newOwners);
    event OwnershipRemoved(address[] indexed removedOwners); 
   
    /**
     * @dev Returns a copy of the whole Set of owners.
     * @notice Returns the addresses of the current owners.
     * @return the array of addresses.
     */
    function getOwners() external view returns (address[] memory);
    
    /**
     * @notice Returns true if address is in _owners.
     * @param _address the address to check.
     * @return whether the _address in _owners.
     */
    function isOwner(address _address) external view returns (bool);

    /**
    * @notice Owner can add new owners to the _owners.
    * @param newOwners the array of addresses to add to _owners
    */
    function addOwners(address[] memory newOwners) external; 

    /**
    * @notice Owner can remove the array of owners from the _owners.
    * @param oldOwners the array of addresses to remove from _owners
    */
    function removeOwners(address[] memory oldOwners) external;

    /**
     * @notice Allows to remove yourself from list of owners. 
     * Note: number of Owners must be more than 1.
     */
    function renounceOwnership() external;  
}
