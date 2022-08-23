// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant DIAMOND_STORAGE_SLOT = keccak256("diamond.standard.diamond.storage");

    struct DStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => EnumerableSet.Bytes32Set) facetToSelectors;
        EnumerableSet.AddressSet facets;
    }

    function getDiamondStorage() internal pure returns (DStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_SLOT;

        assembly {
            ds.slot := position
        }
    }

    function getFacets() public view returns (address[] memory facets) {
        return getDiamondStorage().facets.values();
    }

    function getFacetSelectors(address facet) public view returns (bytes4[] memory selectors) {
        EnumerableSet.Bytes32Set storage f2s = getDiamondStorage().facetToSelectors[facet];

        selectors = new bytes4[](f2s.length());

        for (uint256 i = 0; i < selectors.length; i++) {
            selectors[i] = bytes4(f2s.at(i));
        }
    }

    function getFacetBySelector(bytes4 selector) public view returns (address facet) {
        return getDiamondStorage().selectorToFacet[selector];
    }
}
