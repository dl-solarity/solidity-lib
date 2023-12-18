// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @notice The Diamond standard module
 *
 * DiamondERC165 - Contract implementing ERC165 interface for Diamonds
 */
contract DiamondERC165 is ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // This section of code provides support for the Diamond Loupe and Diamond Cut interfaces.
        // Diamond Loupe interface is defined as: 0x48e2b093
        // Diamond Cut interface is defined as: 0x1f931c1c
        return
            interfaceId == 0x1f931c1c ||
            interfaceId == 0x48e2b093 ||
            super.supportsInterface(interfaceId);
    }
}
