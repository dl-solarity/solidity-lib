// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PermanentOwnable} from "../../access/PermanentOwnable.sol";

contract PermanentOwnableMock is PermanentOwnable {
    event ValidOwner();

    constructor(address _owner) PermanentOwnable(_owner) {}

    function onlyOwnerMethod() external onlyOwner {
        emit ValidOwner();
    }
}
