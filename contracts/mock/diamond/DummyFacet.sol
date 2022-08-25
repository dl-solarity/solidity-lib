// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DummyStorage.sol";

contract DummyFacet is DummyStorage {
    function setDummyString(string calldata dummyString) external {
        getDummyFacetStorage().dummyString = dummyString;
    }
}
