// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.22;

import {OwnableContractsRegistry} from "../../presets/contracts-registry/OwnableContractsRegistry.sol";

contract ContractsRegistryMock is OwnableContractsRegistry {
    string public constant DEPENDANT_NAME = "DEPENDANT";
    string public constant TOKEN_NAME = "TOKEN";

    function mockInit() external {
        __AContractsRegistry_init();
    }

    function getDependantContract() external view returns (address) {
        return getContract(DEPENDANT_NAME);
    }

    function getTokenContract() external view returns (address) {
        return getContract(TOKEN_NAME);
    }
}
