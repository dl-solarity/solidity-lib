// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {AMultiOwnablePoolContractsRegistry} from "../../../../presets/contracts-registry/pools/AMultiOwnablePoolContractsRegistry.sol";

contract MultiOwnablePoolContractsRegistryMock is AMultiOwnablePoolContractsRegistry {
    function addProxyPool(string memory name_, address poolAddress_) public override {
        _addProxyPool(name_, poolAddress_);
    }
}
