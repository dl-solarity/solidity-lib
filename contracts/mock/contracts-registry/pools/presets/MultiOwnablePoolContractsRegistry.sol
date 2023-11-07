// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MultiOwnablePoolContractsRegistry} from "../../../../contracts-registry/pools/presets/MultiOwnablePoolContractsRegistry.sol";

contract MultiOwnablePoolContractsRegistryMock is MultiOwnablePoolContractsRegistry {
    function addProxyPool(string calldata name_, address poolAddress_) external override {
        _addProxyPool(name_, poolAddress_);
    }
}
