// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../libs/math/DSMath.sol";

import "./ICompoundRateKeeperV2.sol";

contract CompoundRateKeeperV2 is ICompoundRateKeeperV2, Ownable {
    using Math for uint256;
    using DSMath for uint256;

    uint256 public currentRate;
    uint256 public annualPercent;

    uint64 public capitalizationPeriod;
    uint64 public lastUpdate;

    bool public hasMaxRateReached;

    constructor(uint256 annualPercent_) {
        require(annualPercent_ >= _getDecimals(), "CRK: annual percent can't be less then 1");

        capitalizationPeriod = 31536000;
        lastUpdate = uint64(block.timestamp);

        annualPercent = annualPercent_;
        currentRate = _getDecimals();
    }

    function setAnnualPercent(uint256 annualPercent_) external override onlyOwner {
        require(!hasMaxRateReached, "CRK: max rate has been reached");
        require(annualPercent_ >= _getDecimals(), "CRK: annual percent can't be less then 1");

        currentRate = getCompoundRate();
        annualPercent = annualPercent_;

        lastUpdate = uint64(block.timestamp);

        emit AnnualPercentChanged(annualPercent_);
    }

    function setCapitalizationPeriod(uint32 capitalizationPeriod_) external override onlyOwner {
        require(!hasMaxRateReached, "CRK: max rate has been reached");
        require(capitalizationPeriod_ > 0, "CRK: invalid value");

        currentRate = getCompoundRate();
        capitalizationPeriod = capitalizationPeriod_;

        lastUpdate = uint64(block.timestamp);

        emit CapitalizationPeriodChanged(capitalizationPeriod_);
    }

    function emergencyUpdateCompoundRate() external override {
        try this.getCompoundRate() returns (uint256 rate_) {
            if (rate_ == _getMaxRate()) hasMaxRateReached = true;
        } catch {
            hasMaxRateReached = true;
        }
    }

    /// @dev Calculate compound rate for this moment.
    function getCompoundRate() public view override returns (uint256) {
        return _getPotentialCompoundRate(uint64(block.timestamp));
    }

    /**
     * @dev Calculate compound rate at a particular time.
     *
     * Main contract logic, calculate actual compound rate.
     * If rate bigger than _getMaxRate(), return _getMaxRate().
     * If function is reverted by overflow, call emergencyUpdateCompoundRate().
     */
    function getPotentialCompoundRate(uint64 timestamp_) public view override returns (uint256) {
        return _getPotentialCompoundRate(timestamp_);
    }

    function _getPotentialCompoundRate(uint64 timestamp_) private view returns (uint256) {
        if (hasMaxRateReached) return _getMaxRate();

        uint64 lastUpdate_ = lastUpdate;

        // Require is made to avoid incorrect calculations at the front
        require(lastUpdate_ <= timestamp_, "CRK: invalid timestamp");

        if (timestamp_ == lastUpdate_) return currentRate;

        uint64 secondsPassed_ = timestamp_ - lastUpdate_;

        uint64 capitalizationPeriod_ = capitalizationPeriod;
        uint64 capitalizationPeriodsNum_ = secondsPassed_ / capitalizationPeriod_;
        uint64 secondsLeft_ = secondsPassed_ % capitalizationPeriod_;

        uint256 annualPercent_ = annualPercent;
        uint256 rate_ = currentRate;

        if (capitalizationPeriodsNum_ != 0) {
            uint256 capitalizationPeriod_Rate = annualPercent_.rpow(
                capitalizationPeriodsNum_,
                _getDecimals()
            );
            rate_ = (rate_ * capitalizationPeriod_Rate) / _getDecimals();
        }

        if (secondsLeft_ > 0) {
            uint256 rateLeft_ = _getDecimals() +
                ((annualPercent_ - _getDecimals()) * secondsLeft_) /
                capitalizationPeriod_;
            rate_ = (rate_ * rateLeft_) / _getDecimals();
        }

        return rate_.min(_getMaxRate());
    }

    /// @dev Max accessible compound rate.
    function _getMaxRate() private pure returns (uint256) {
        return type(uint128).max * _getDecimals();
    }

    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }
}
