// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableContractsRegistry} from "../../contracts-registry/presets/OwnableContractsRegistry.sol";

contract ContractsRegistry1 is OwnableContractsRegistry {
    string public constant CRDEPENDANT_NAME = "CRDEPENDANT";
    string public constant TOKEN_NAME = "TOKEN";

    function mockInit() external {
        __ContractsRegistry_init();
    }

    function getCRDependantContract() external view returns (address) {
        return getContract(CRDEPENDANT_NAME);
    }

    function getTokenContract() external view returns (address) {
        return getContract(TOKEN_NAME);
    }
}
