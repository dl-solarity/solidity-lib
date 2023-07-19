// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DiamondStorage} from "./DiamondStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is a custom implementation of a Diamond Proxy standard (https://eips.ethereum.org/EIPS/eip-2535).
 * This contract acts as a highest level contract of that standard. What is different from the EIP2535,
 * in order to use the DiamondStorage, storage is defined in a separate contract that the facets have to inherit from,
 * not an internal library.
 *
 * As a convention, view and pure function should be defined in the storage contract while function that modify state, in
 * the facet itself.
 *
 * If you wish to add a receive() function, you can attach a "0x00000000" selector to a facet that has such function.
 */
contract Diamond is DiamondStorage {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice The payable fallback function that delegatecall's the facet with associated selector
     */
    // solhint-disable-next-line
    fallback() external payable virtual {
        address facet_ = getFacetBySelector(msg.sig);

        require(facet_ != address(0), "Diamond: selector is not registered");

        _beforeFallback(facet_, msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result_ := delegatecall(gas(), facet_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result_
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice The internal function to add facets to a diamond (aka diamondCut())
     * @param facet_ the implementation address
     * @param selectors_ the function selectors the implementation has
     */
    function _addFacet(address facet_, bytes4[] memory selectors_) internal {
        require(facet_.isContract(), "Diamond: facet is not a contract");
        require(selectors_.length > 0, "Diamond: no selectors provided");

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            require(
                _ds.selectorToFacet[selectors_[i]] == address(0),
                "Diamond: selector already added"
            );

            _ds.selectorToFacet[selectors_[i]] = facet_;
            _ds.facetToSelectors[facet_].add(bytes32(selectors_[i]));
        }

        _ds.facets.add(facet_);
    }

    /**
     * @notice The internal function to remove facets from the diamond
     * @param facet_ the implementation to be removed. The facet itself will be removed only if there are no selectors left
     * @param selectors_ the selectors of that implementation to be removed
     */
    function _removeFacet(address facet_, bytes4[] memory selectors_) internal {
        require(selectors_.length > 0, "Diamond: no selectors provided");

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            require(
                _ds.selectorToFacet[selectors_[i]] == facet_,
                "Diamond: selector from another facet"
            );

            _ds.selectorToFacet[selectors_[i]] = address(0);
            _ds.facetToSelectors[facet_].remove(bytes32(selectors_[i]));
        }

        if (_ds.facetToSelectors[facet_].length() == 0) {
            _ds.facets.remove(facet_);
        }
    }

    /**
     * @notice The internal function to update the facets of the diamond
     * @param facet_ the facet to update
     * @param fromSelectors_ the selectors to remove from the facet
     * @param toSelectors_ the selectors to add to the facet
     */
    function _updateFacet(
        address facet_,
        bytes4[] memory fromSelectors_,
        bytes4[] memory toSelectors_
    ) internal {
        _addFacet(facet_, toSelectors_);
        _removeFacet(facet_, fromSelectors_);
    }

    function _beforeFallback(address facet_, bytes4 selector_) internal virtual {}
}
