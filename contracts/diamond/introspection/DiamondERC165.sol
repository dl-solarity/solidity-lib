// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {DiamondStorage} from "../DiamondStorage.sol";

/**
 * @notice DiamondERC165 - Contract implementing ERC165 interface for Diamonds
 */
contract DiamondERC165 is ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // This section of code provides support for the Diamond Loupe interface.
        // Diamond Loupe interface is defined as: 0x48e2b093
        return
            interfaceId ==
            bytes4(
                DiamondStorage.facets.selector ^
                    DiamondStorage.facetFunctionSelectors.selector ^
                    DiamondStorage.facetAddresses.selector ^
                    DiamondStorage.facetAddress.selector
            ) ||
            super.supportsInterface(interfaceId);
    }
}
