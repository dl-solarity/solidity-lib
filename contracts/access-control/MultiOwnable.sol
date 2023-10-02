// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SetHelper} from "../libs/arrays/SetHelper.sol";
import {TypeCaster} from "../libs/utils/TypeCaster.sol";
import {IMultiOwnable} from "../interfaces/access-control/IMultiOwnable.sol";

/**
 * @notice The MultiOwnable module
 *
 * Contract module which provides a basic access control mechanism, where there is a list of
 * owner addresses those can be granted exclusive access to specific functions.
 * All owners are equal in their access, they can add new owners, also remove each other and themself.
 *
 * By default, the owner account will be the one that deploys the contract.
 *
 * This module will make available the modifier `onlyOwner`, which can be applied
 * to your functions to restrict their use to the owners.
 */
abstract contract MultiOwnable is IMultiOwnable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TypeCaster for address;
    using SetHelper for EnumerableSet.AddressSet;

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
     * Null address will not be added and function will be reverted.
     * @dev Internal function without access restriction.
     * @param newOwners_ the array of addresses to add to _owners
     */
    function _addOwners(address[] memory newOwners_) private {
        _owners.add(newOwners_);

        require(!_owners.contains(address(0)), "MultiOwnable: zero address can not be added");

        emit OwnersAdded(newOwners_);
    }

    /**
     * @notice Removes ownership of the contract for every address in array.
     *
     * Note: removing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     *
     * @dev Internal function without access restriction.
     * @param oldOwners_ the array of addresses to remove from _owners
     */
    function _removeOwners(address[] memory oldOwners_) private {
        _owners.remove(oldOwners_);

        emit OwnersRemoved(oldOwners_);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() private view {
        require(isOwner(msg.sender), "MultiOwnable: caller is not the owner");
    }
}
