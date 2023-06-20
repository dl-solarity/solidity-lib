// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libs/utils/TypeCaster.sol";
import "../interfaces/access-control/IMultiOwnable.sol";


abstract contract AbstractMultiOwnable is IMultiOwnable, Initializable {  
    using EnumerableSet for EnumerableSet.AddressSet;

    using TypeCaster for address;

    EnumerableSet.AddressSet private _owners;
    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    
    /** 
    * @dev Initializes the contract setting the msg.sender as the initial owner.
    */    
    function __AbstractMultiOwnable_init() internal onlyInitializing {        
        _owners.add(msg.sender);  

        emit OwnershipAdded(msg.sender.asSingletonArray());     
    }

    function getOwners() public view virtual override returns (address[] memory) {
        return _owners.values();
    }    

    function isOwner(address _address) public view virtual override returns (bool) {
        return _owners.contains(_address);
    }    

    function addOwners(address[] memory newOwners) external virtual override onlyOwner {   
        _addOwners(newOwners); 
    }    

    function removeOwners(address[] memory oldOwners) external virtual override onlyOwner {      
        _removeOwners(oldOwners);
    }    
    
    function renounceOwnership() external virtual override onlyOwner {
        require(_owners.length() > 1, "AbstractMultiOwnable: only one owner, cannot renounce ownership");
        _owners.remove(msg.sender);
    
        emit OwnershipRemoved(msg.sender.asSingletonArray());
    }    

    /**
    * @dev Throws if the sender is not the owner.
    */
    function _checkOwner() internal view virtual {
        require(_owners.contains(msg.sender), "AbstractMultiOwnable: caller is not the owner");
    }

    /**
     * @notice Gives ownership of the contract to array of new owners.
     * Internal function without access restriction.
     * Address(0) will not be added and function will be reverted.
     * @param newOwners the array of addresses to add to _owners
     */
    function _addOwners(address[] memory newOwners) internal virtual {
        for (uint i = 0; i < newOwners.length; i++) {
            require (newOwners[i] != address(0), "AbstractMultiOwnable: zero address can not be added");
            _owners.add(newOwners[i]);
        }         
        
        emit OwnershipAdded(newOwners); 
    }    

    /**
     * @notice Removes ownership of the contract for every address in array.
     * Internal function without access restriction.
     * If no owners left, function will be reverted.
     * @param oldOwners the array of addresses to remove from _owners
     */
    function _removeOwners(address[] memory oldOwners) internal virtual {
        for (uint i = 0; i < oldOwners.length; i++) {      
            _owners.remove(oldOwners[i]);
        }        
        require(_owners.length() >= 1, "AbstractMultiOwnable: no owners left after removal");

        emit OwnershipRemoved(oldOwners);
    }
}




    

