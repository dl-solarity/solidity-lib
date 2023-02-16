// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../AbstractConstantsRegistry.sol";

contract OwnableConstantsRegistry is AbstractConstantsRegistry, OwnableUpgradeable {
    function __OwnableConstantsRegistry_init() public initializer {
        __Ownable_init();
        __ConstantsRegistry_init();
    }

    function setUint256Constant(string[] memory key_, uint256 value_) external onlyOwner {
        _setUint256Constant(key_, value_);
    }
}
