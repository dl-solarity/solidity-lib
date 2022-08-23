// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnableDiamondStorage {
    bytes32 constant OWNABLE_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.ownablediamond.storage");

    struct ODStorage {
        address owner;
    }

    function getOwnableDiamondStorage() internal pure returns (ODStorage storage ods) {
        bytes32 position = OWNABLE_DIAMOND_STORAGE_SLOT;

        assembly {
            ods.slot := position
        }
    }

    modifier onlyOwner() {
        address owner = getOwnableDiamondStorage().owner;

        require(owner == address(0) || owner == msg.sender, "ODStorage: not an owner");
        _;
    }
}
