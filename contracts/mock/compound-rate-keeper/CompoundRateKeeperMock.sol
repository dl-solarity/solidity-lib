// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../compound-rate-keeper/presets/OwnableCompoundRateKeeper.sol";

contract CompoundRateKeeperMock is OwnableCompoundRateKeeper {
    function mockInit(uint256 capitalizationRate_, uint64 capitalizationPeriod_) external {
        __CompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }
}
