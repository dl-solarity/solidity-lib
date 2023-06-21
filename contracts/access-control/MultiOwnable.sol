// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {TypeCaster} from "../libs/utils/TypeCaster.sol";
import {IMultiOwnable} from "../interfaces/access-control/IMultiOwnable.sol";

abstract contract MultiOwnable is IMultiOwnable, Initializable {
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
    function __MultiOwnable_init() internal onlyInitializing {
        _addOwners(msg.sender.asSingletonArray());
    }

    function addOwners(address[] memory newOwners_) public virtual override onlyOwner {
        _addOwners(newOwners_);
    }

    function removeOwners(address[] memory oldOwners_) public virtual override onlyOwner {
        _removeOwners(oldOwners_);
    }

    function renounceOwnership() public virtual override onlyOwner {
        _removeOwners(msg.sender.asSingletonArray());
    }

    function getOwners() public view virtual override returns (address[] memory) {
        return _owners.values();
    }

    function isOwner(address address_) public view virtual override returns (bool) {
        return _owners.contains(address_);
    }

    /**
     * @notice Gives ownership of the contract to array of new owners.
     * Internal function without access restriction.
     * Address(0) will not be added and function will be reverted.
     * @param newOwners_ the array of addresses to add to _owners
     */
    function _addOwners(address[] memory newOwners_) private {
        for (uint256 i = 0; i < newOwners_.length; i++) {
            require(newOwners_[i] != address(0), "MultiOwnable: zero address can not be added");
            _owners.add(newOwners_[i]);
        }

        emit OwnerAdded(newOwners_);
    }

    /**
     * @notice Removes ownership of the contract for every address in array.
     * Internal function without access restriction.
     * Note: removing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     * @param oldOwners_ the array of addresses to remove from _owners
     */
    function _removeOwners(address[] memory oldOwners_) private {
        for (uint256 i = 0; i < oldOwners_.length; i++) {
            _owners.remove(oldOwners_[i]);
        }

        emit OwnerRemoved(oldOwners_);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() private view {
        require(isOwner(msg.sender), "MultiOwnable: caller is not the owner");
    }
}
