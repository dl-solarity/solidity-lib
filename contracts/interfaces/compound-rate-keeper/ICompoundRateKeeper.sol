// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The Compound Rate Keeper module
 */
interface ICompoundRateKeeper {
    event CapitalizationPeriodChanged(uint256 newCapitalizationPeriod);
    event CapitalizationRateChanged(uint256 newCapitalizationRate);

    function emergencyUpdateCompoundRate() external;

    function getCompoundRate() external view returns (uint256);

    function getFutureCompoundRate(uint64 timestamp_) external view returns (uint256);

    function getCapitalizationRate() external view returns (uint256);

    function getCapitalizationPeriod() external view returns (uint64);

    function getLastUpdate() external view returns (uint64);

    function getIsMaxRateReached() external view returns (bool);

    function getCurrentRate() external view returns (uint256);
}
