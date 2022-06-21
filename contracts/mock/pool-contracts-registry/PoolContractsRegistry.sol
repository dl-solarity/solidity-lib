// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../pool-contracts-registry/AbstractPoolContractsRegistry.sol";

contract PoolContractsRegistry is AbstractPoolContractsRegistry {
    string public constant POOL_1_NAME = "POOL_1";
    string public constant POOL_2_NAME = "POOL_2";

    function _onlyPoolFactory() internal view override {
        require(owner() == msg.sender, "PoolContractsRegistry: not an owner");
    }
}
