// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The Diamond standard module
 *
 * The storage contract of Ownable Diamond preset
 */
abstract contract OwnableDiamondStorage {
    bytes32 public constant OWNABLE_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.ownablediamond.storage");

    struct ODStorage {
        address owner;
    }

    modifier onlyOwner() {
        address diamondOwner_ = owner();

        require(
            diamondOwner_ == address(0) || diamondOwner_ == msg.sender,
            "ODStorage: not an owner"
        );
        _;
    }

    function _getOwnableDiamondStorage() internal pure returns (ODStorage storage _ods) {
        bytes32 slot_ = OWNABLE_DIAMOND_STORAGE_SLOT;

        assembly {
            _ods.slot := slot_
        }
    }

    /**
     * @notice The function to get the Diamond owner
     * @return the owner of the Diamond
     */
    function owner() public view returns (address) {
        return _getOwnableDiamondStorage().owner;
    }
}
