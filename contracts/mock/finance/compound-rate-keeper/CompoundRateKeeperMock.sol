// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ACompoundRateKeeper} from "../../../finance/compound-rate-keeper/ACompoundRateKeeper.sol";

contract CompoundRateKeeperMock is ACompoundRateKeeper, OwnableUpgradeable {
    function __CompoundRateKeeperMock_init(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) public initializer {
        __Ownable_init(msg.sender);
        __ACompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    function mockInit(uint256 capitalizationRate_, uint64 capitalizationPeriod_) external {
        __ACompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    function setCapitalizationRateAndPeriod(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) external {
        _setCapitalizationRate(capitalizationRate_);
        _setCapitalizationPeriod(capitalizationPeriod_);
    }

    function setCapitalizationRate(uint256 capitalizationRate_) external {
        _setCapitalizationRate(capitalizationRate_);
    }

    function setCapitalizationPeriod(uint64 capitalizationPeriod_) external {
        _setCapitalizationPeriod(capitalizationPeriod_);
    }
}
