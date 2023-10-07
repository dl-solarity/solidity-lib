// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableDiamond} from "../../diamond/presets/OwnableDiamond/OwnableDiamond.sol";

/**
 * @notice The Ownable preset of Diamond proxy
 */
contract OwnableDiamondMock is OwnableDiamond {
    function diamondCutShort(Facet[] memory facets_) public {
        diamondCut(facets_);
    }

    function diamondCutLong(Facet[] memory facets_, address init_, bytes memory calldata_) public {
        diamondCut(facets_, init_, calldata_);
    }
}
