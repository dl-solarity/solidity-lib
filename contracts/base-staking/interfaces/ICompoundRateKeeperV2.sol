// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ICompoundRateKeeperV2 {
    event CapitalizationPeriodChanged(uint256 indexed newCapitalizationPeriod);
    event AnnualPercentChanged(uint256 indexed newAnnualPercent);

    /// @notice Set new annual percent
    /// @param _annualPercent = 1*10^27 (0% per period), 1.1*10^27 (10% per period), 2*10^27 (100% per period)
    function setAnnualPercent(uint256 _annualPercent) external;

    /// @notice Set new capitalization period
    /// @param _capitalizationPeriod Seconds
    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external;

    /**
     * @notice Call this function only when getCompoundRate() or getPotentialCompoundRate()
     * throw error. Update hasMaxRateReached switcher to `true`.
     */
    function emergencyUpdateCompoundRate() external;

    /**
     * @notice Calculate compound rate for this moment.
     */
    function getCompoundRate() external view returns (uint256);

    /**
     * @notice Calculate compound rate at a particular time.
     * @param _timestamp Given timestamp, seconds.
     *
     * @dev Main contract logic, calculate actual compound rate.
     * If rate bigger than __getMaxRate(), return __getMaxRate().
     * If function is reverted by overflow, call emergencyUpdateCompoundRate()
     */
    function getPotentialCompoundRate(uint64 _timestamp) external view returns (uint256);
}
