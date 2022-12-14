// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice The storage contract of Ownable Diamond preset
 */
contract OwnableDiamondStorage {
    bytes32 public constant OWNABLE_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.ownablediamond.storage");

    struct ODStorage {
        address owner;
    }

    function getOwnableDiamondStorage() internal pure returns (ODStorage storage ods) {
        bytes32 slot = OWNABLE_DIAMOND_STORAGE_SLOT;

        assembly {
            ods.slot := slot
        }
    }

    modifier onlyOwner() {
        address diamondOwner = owner();

        require(
            diamondOwner == address(0) || diamondOwner == msg.sender,
            "ODStorage: not an owner"
        );
        _;
    }

    function owner() public view returns (address) {
        return getOwnableDiamondStorage().owner;
    }
}
