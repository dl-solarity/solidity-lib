// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../contracts-registry/AbstractContractsRegistry.sol";

contract ContractsRegistry1 is AbstractContractsRegistry {
    string public constant CRDEPENDANT_NAME = "CRDEPENDANT";
    string public constant TOKEN_NAME = "TOKEN";

    function getCRDependantContract() external view returns (address) {
        return getContract(CRDEPENDANT_NAME);
    }

    function getTokenContract() external view returns (address) {
        return getContract(TOKEN_NAME);
    }
}
