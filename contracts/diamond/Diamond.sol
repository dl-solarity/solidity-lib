// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./DiamondStorage.sol";

contract Diamond is DiamondStorage {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    fallback() external payable {
        address facet = getFacetBySelector(msg.sig);

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

    receive() external payable {}

    function _addFacet(address facet, bytes4[] memory selectors) internal {
        require(facet.isContract(), "Diamond: facet is not a contract");

        DStorage storage ds = getDiamondStorage();

        for (uint256 i = 0; i < selectors.length; i++) {
            require(
                ds.selectorToFacet[selectors[i]] == address(0),
                "Diamond: selector already added"
            );

            ds.selectorToFacet[selectors[i]] = facet;
            ds.facetToSelectors[facet].add(bytes32(selectors[i]));
        }

        if (ds.facetToSelectors[facet].length() > 0) {
            ds.facets.add(facet);
        }
    }

    function _removeFacet(address facet, bytes4[] memory selectors) internal {
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
}
