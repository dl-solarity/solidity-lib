// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISchedule {
    // properties for vesting schedule
    struct Schedule {
        uint256 startTimestamp;
        uint256 periodSeconds;
        uint256 cliffInPeriods;
        uint256 portionOfTotal;
        uint256 portionPerPeriod;
    }

    function calculate(Schedule memory schedule_, uint256 amount_) external view returns (uint256);
}
