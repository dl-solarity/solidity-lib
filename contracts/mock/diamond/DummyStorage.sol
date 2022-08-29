// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DummyStorage {
    bytes32 public constant DUMMY_STORAGE_SLOT = keccak256("diamond.standard.dummyfacet.storage");

    struct DummyFacetStorage {
        string dummyString;
    }

    function getDummyFacetStorage() internal pure returns (DummyFacetStorage storage ods) {
        bytes32 position = DUMMY_STORAGE_SLOT;

        assembly {
            ods.slot := position
        }
    }

    function getDummyString() external view returns (string memory dummyString) {
        return getDummyFacetStorage().dummyString;
    }
}
