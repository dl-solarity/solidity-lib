// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISchedule} from "./ISchedule.sol";
import {PRECISION} from "../../utils/Globals.sol";

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

contract LinearSchedule is ISchedule {
    using MathUpgradeable for uint256;

    // calculation of linear vesting
    function calculate(
        Schedule memory schedule_,
        uint256 amount_
    ) public view virtual returns (uint256) {
        uint256 _elapsedPeriods = _calculateElapsedPeriods(schedule_);

        if (_elapsedPeriods <= schedule_.cliffInPeriods) return 0;

        // amount we should get after vesting
        uint256 _totalVestingAmount = (amount_ * schedule_.portionOfTotal) / (PRECISION);

        // amount we should get at the end of one period
        uint256 _amountPerPeriod = (_totalVestingAmount * schedule_.portionPerPeriod) /
            (PRECISION);

        return (_amountPerPeriod * _elapsedPeriods).min(_totalVestingAmount);
    }

    // calculate elapsed periods
    function _calculateElapsedPeriods(Schedule memory schedule_) internal view returns (uint256) {
        return (block.timestamp - schedule_.startTimestamp) / (schedule_.periodSeconds);
    }
}
