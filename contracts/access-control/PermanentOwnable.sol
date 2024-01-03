// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice The PermanentOwnable module
 *
 * Contract module which provides a basic access control mechanism, where there is
 * an account (an owner) that can be granted exclusive access to specific functions.
 *
 * The owner is set to the address provided by the deployer. This cannot be further changed.
 *
 * This module will make available the modifier `onlyOwner`, which can be applied
 * to your functions to restrict their use to the owners.
 */
abstract contract PermanentOwnable {
    using Address for address;

    address private immutable _OWNER;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_OWNER == msg.sender, "PermanentOwnable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the owner.
     */
    constructor(address _owner) {
        require(_owner != address(0), "PermanentOwnable: zero address can not be the owner");
        _OWNER = _owner;
    }

    /**
     * @dev Returns the address of the owner.
     */
    function owner() public view returns (address) {
        return _OWNER;
    }
}
