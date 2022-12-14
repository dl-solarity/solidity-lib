// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 *  @notice The Diamond standard module
 *
 *  This is the storage contract for the diamond proxy
 */
contract DiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  @notice The struct slot where the storage is
     */
    bytes32 public constant DIAMOND_STORAGE_SLOT = keccak256("diamond.standard.diamond.storage");

    /**
     *  @notice The storage of the Diamond proxy
     */
    struct DStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => EnumerableSet.Bytes32Set) facetToSelectors;
        EnumerableSet.AddressSet facets;
    }

    /**
     *  @notice The internal function to get the diamond proxy storage
     *  @return ds the struct from the DIAMOND_STORAGE_SLOT
     */
    function getDiamondStorage() internal pure returns (DStorage storage ds) {
        bytes32 slot = DIAMOND_STORAGE_SLOT;

        assembly {
            ds.slot := slot
        }
    }

    /**
     *  @notice The function to get all the facets of this diamond
     *  @return facets the array of facets' addresses
     */
    function getFacets() public view returns (address[] memory facets) {
        return getDiamondStorage().facets.values();
    }

    /**
     *  @notice The function to get all the selectors assigned to the facet
     *  @param facet the facet to get assigned selectors of
     *  @return selectors the array of assigned selectors
     */
    function getFacetSelectors(address facet) public view returns (bytes4[] memory selectors) {
        EnumerableSet.Bytes32Set storage f2s = getDiamondStorage().facetToSelectors[facet];

        selectors = new bytes4[](f2s.length());

        for (uint256 i = 0; i < selectors.length; i++) {
            selectors[i] = bytes4(f2s.at(i));
        }
    }

    /**
     *  @notice The function to get associated facet by the selector
     *  @param selector the selector
     *  @return facet the associated facet address
     */
    function getFacetBySelector(bytes4 selector) public view returns (address facet) {
        return getDiamondStorage().selectorToFacet[selector];
    }
}
