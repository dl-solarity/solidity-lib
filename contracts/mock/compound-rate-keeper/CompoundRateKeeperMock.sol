// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableCompoundRateKeeper} from "../../compound-rate-keeper/presets/OwnableCompoundRateKeeper.sol";

contract CompoundRateKeeperMock is OwnableCompoundRateKeeper {
    function mockInit(uint256 capitalizationRate_, uint64 capitalizationPeriod_) external {
        __CompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    function setCapitalizationRateAndPeriod(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) external onlyOwner {
        _setCapitalizationRate(capitalizationRate_);
        _setCapitalizationPeriod(capitalizationPeriod_);
    }

    function rpow(uint256 x_, uint256 n_, uint256 b_) external pure returns (uint256 z_) {
        return _rpow(x_, n_, b_);
    }
}
