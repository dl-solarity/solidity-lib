// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableContractsRegistry} from "../../contracts-registry/presets/OwnableContractsRegistry.sol";

contract ContractsRegistryMock is OwnableContractsRegistry {
    string public constant DEPENDANT_NAME = "DEPENDANT";
    string public constant TOKEN_NAME = "TOKEN";

    function mockInit() external {
        __ContractsRegistry_init();
    }

    function getDependantContract() external view returns (address) {
        return getContract(DEPENDANT_NAME);
    }

    function getTokenContract() external view returns (address) {
        return getContract(TOKEN_NAME);
    }
}
