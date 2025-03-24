// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {OwnableDiamond} from "../../presets/diamond/OwnableDiamond.sol";

contract OwnableDiamondMock is OwnableDiamond {
    function __OwnableDiamondDirect_init() external {
        __Ownable_init(msg.sender);
    }

    function __OwnableDiamondMock_init() external initializer {
        __Ownable_init(msg.sender);
    }

    function diamondCutShort(Facet[] memory facets_) public {
        diamondCut(facets_);
    }

    function diamondCutLong(Facet[] memory facets_, address init_, bytes memory calldata_) public {
        diamondCut(facets_, init_, calldata_);
    }
}
