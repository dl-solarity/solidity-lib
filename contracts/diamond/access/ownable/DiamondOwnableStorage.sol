// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {InitializableStorage} from "../../utils/InitializableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is an Ownable Storage contract with Diamond Standard support
 */
abstract contract DiamondOwnableStorage is InitializableStorage {
    bytes32 public constant DIAMOND_OWNABLE_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.ownable.storage");

    struct DOStorage {
        address owner;
    }

    modifier onlyOwner() {
        address diamondOwner_ = owner();

        require(
            diamondOwner_ == address(0) || diamondOwner_ == msg.sender,
            "DiamondOwnable: not an owner"
        );
        _;
    }

    function _getDiamondOwnableStorage() internal pure returns (DOStorage storage _dos) {
        bytes32 slot_ = DIAMOND_OWNABLE_STORAGE_SLOT;

        assembly {
            _dos.slot := slot_
        }
    }

    /**
     * @notice The function to get the Diamond owner
     * @return the owner of the Diamond
     */
    function owner() public view returns (address) {
        return _getDiamondOwnableStorage().owner;
    }
}
