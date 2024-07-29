// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DiamondERC165} from "../../../diamond/introspection/DiamondERC165.sol";
import {DiamondStorage} from "../../../diamond/DiamondStorage.sol";

contract DiamondERC165Mock is DiamondERC165 {
    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return
            interfaceId_ == type(DiamondStorage).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
