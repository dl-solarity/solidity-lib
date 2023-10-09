// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DummyFacet} from "./DummyFacet.sol";

contract DummyInit is DummyFacet {
    event Initialized();

    function init() external {
        setDummyString("dummy facet initialized");
        emit Initialized();
    }

    function initWithError() external pure {
        revert();
    }

    function initWithErrorMsg() external pure {
        revert("DiamondInit: init error");
    }
}
