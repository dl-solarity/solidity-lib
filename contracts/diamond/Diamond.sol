// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

import "./DiamondStorage.sol";

/**
 *  @notice The Diamond standard module
 *
 *  This is a custom implementation of a Diamond Proxy standard (https://eips.ethereum.org/EIPS/eip-2535).
 *  This contract acts as a highest level contract of that standard. What is different from the EIP2535,
 *  in order to use the DiamondStorage, storage is defined in a separate contract that the facets have to inherit from,
 *  not an internal library.
 *
 *  As a convention, view and pure function should be defined in the storage contract while function that modify state, in
 *  the facet itself.
 *
 *  If you wish to add a receive() function, you can attach a "0x00000000" selector to a facet that has such function.
 */
contract Diamond is DiamondStorage {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  @notice The payable fallback function that delegatecall's the facet with associated selector
     */
    fallback() external payable {
        address facet = getFacetBySelector(msg.sig);

        require(facet != address(0), "Diamond: selector is not registered");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     *  @notice The internal function to add facets to a diamond (aka diamondCut())
     *  @param facet the implementation address
     *  @param selectors the function selectors the implementation has
     */
    function _addFacet(address facet, bytes4[] memory selectors) internal {
        require(facet.isContract(), "Diamond: facet is not a contract");
        require(selectors.length > 0, "Diamond: no selectors provided");

        DStorage storage ds = getDiamondStorage();

        for (uint256 i = 0; i < selectors.length; i++) {
            require(
                ds.selectorToFacet[selectors[i]] == address(0),
                "Diamond: selector already added"
            );

            ds.selectorToFacet[selectors[i]] = facet;
            ds.facetToSelectors[facet].add(bytes32(selectors[i]));
        }

        ds.facets.add(facet);
    }

    /**
     *  @notice The internal function to remove facets from the diamond
     *  @param facet the implementation to be removed. The facet itself will be removed only if there are no selectors left
     *  @param selectors the selectors of that implementation to be removed
     */
    function _removeFacet(address facet, bytes4[] memory selectors) internal {
        require(selectors.length > 0, "Diamond: no selectors provided");

        DStorage storage ds = getDiamondStorage();

        for (uint256 i = 0; i < selectors.length; i++) {
            require(
                ds.selectorToFacet[selectors[i]] == facet,
                "Diamond: selector from another facet"
            );

            ds.selectorToFacet[selectors[i]] = address(0);
            ds.facetToSelectors[facet].remove(bytes32(selectors[i]));
        }

        if (ds.facetToSelectors[facet].length() == 0) {
            ds.facets.remove(facet);
        }
    }

    /**
     *  @notice The internal function to update the facets of the diamond
     *  @param facet the facet to update
     *  @param fromSelectors the selectors to remove from the facet
     *  @param toSelectors the selectors to add to the facet
     */
    function _updateFacet(
        address facet,
        bytes4[] memory fromSelectors,
        bytes4[] memory toSelectors
    ) internal {
        _addFacet(facet, toSelectors);
        _removeFacet(facet, fromSelectors);
    }
}
