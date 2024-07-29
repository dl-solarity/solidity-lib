// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {DiamondStorage} from "../../diamond/DiamondStorage.sol";
import {DummyStorageMock} from "./DummyStorageMock.sol";

contract DummyFacetMock is ERC165, DummyStorageMock {
    function setDummyString(string memory dummyString_) public {
        getDummyFacetStorage().dummyString = dummyString_;
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return
            interfaceId_ == type(DiamondStorage).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
