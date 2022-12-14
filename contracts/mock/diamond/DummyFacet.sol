// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DummyStorage.sol";

contract DummyFacet is DummyStorage {
    function setDummyString(string calldata dummyString) external {
        getDummyFacetStorage().dummyString = dummyString;
    }

    receive() external payable {}
}
