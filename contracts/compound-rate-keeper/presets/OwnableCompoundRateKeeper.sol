// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {AbstractCompoundRateKeeper} from "../AbstractCompoundRateKeeper.sol";

/**
 * @notice The Ownable preset of CompoundRateKeeper
 */
contract OwnableCompoundRateKeeper is AbstractCompoundRateKeeper, OwnableUpgradeable {
    function __OwnableCompoundRateKeeper_init(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) public initializer {
        __Ownable_init();
        __CompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    function setCapitalizationRate(uint256 capitalizationRate_) external onlyOwner {
        _setCapitalizationRate(capitalizationRate_);
    }

    function setCapitalizationPeriod(uint64 capitalizationPeriod_) external onlyOwner {
        _setCapitalizationPeriod(capitalizationPeriod_);
    }
}
