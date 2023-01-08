// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/compound-rate-keeper/ICompoundRateKeeper.sol";

import "../libs/math/DSMath.sol";

import "../utils/Globals.sol";

/**
 *  @notice The Compound Rate Keeper module
 *
 *  The purpose of this module is to calculate the compound interest rate via 2 parameters:
 *  capitalizationRate and capitalizationPeriod.
 *
 *  The CompoundRateKeeper can be used in landing protocols to calculate the interest and borrow rates. It can
 *  also be used in regular staking contracts to get users' rewards accrual.
 *
 *  The compound rate is calculated with 10**25 precision.
 *  The maximal possible compound rate is (type(uint128).max * 10**25)
 */
abstract contract AbstractCompoundRateKeeper is ICompoundRateKeeper, Initializable {
    using Math for uint256;
    using DSMath for uint256;

    uint256 public capitalizationRate;
    uint64 public capitalizationPeriod;

    uint64 public lastUpdate;

    bool public isMaxRateReached;

    uint256 internal _currentRate;

    /**
     *  @notice The proxy initializer function
     */
    function __CompoundRateKeeper_init(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) internal onlyInitializing {
        _currentRate = PRECISION;
        lastUpdate = uint64(block.timestamp);

        _changeCapitalizationRate(capitalizationRate_);
        _changeCapitalizationPeriod(capitalizationPeriod_);
    }

    /**
     *  @notice The function to force-update the compound rate if the getter reverts, sets isMaxRateReached to true
     */
    function emergencyUpdateCompoundRate() public override {
        try this.getCompoundRate() returns (uint256 rate_) {
            if (rate_ == _getMaxRate()) {
                isMaxRateReached = true;
            }
        } catch {
            isMaxRateReached = true;
        }
    }

    /**
     *  @notice The function to get current compound rate
     *  @return current compound rate
     */
    function getCompoundRate() public view override returns (uint256) {
        return getFutureCompoundRate(uint64(block.timestamp));
    }

    /**
     *  @notice The function to get future compound rate (the timestamp_ may be equal to the lastUpdate)
     *  @param timestamp_ the timestamp to calculate the rate for
     *  @return the compound rate for the provided timestamp
     */
    function getFutureCompoundRate(uint64 timestamp_) public view override returns (uint256) {
        if (isMaxRateReached) {
            return _getMaxRate();
        }

        uint64 lastUpdate_ = lastUpdate;

        if (lastUpdate_ >= timestamp_) {
            return _currentRate;
        }

        uint64 secondsPassed_ = timestamp_ - lastUpdate_;

        uint64 capitalizationPeriod_ = capitalizationPeriod;
        uint64 capitalizationPeriodsNum_ = secondsPassed_ / capitalizationPeriod_;
        uint64 secondsLeft_ = secondsPassed_ % capitalizationPeriod_;

        uint256 capitalizationRate_ = capitalizationRate;
        uint256 rate_ = _currentRate;

        if (capitalizationPeriodsNum_ != 0) {
            uint256 capitalizationPeriodRate_ = capitalizationRate_.rpow(
                capitalizationPeriodsNum_,
                PRECISION
            );
            rate_ = (rate_ * capitalizationPeriodRate_) / PRECISION;
        }

        if (secondsLeft_ > 0) {
            uint256 rateLeft_ = PRECISION +
                ((capitalizationRate_ - PRECISION) * secondsLeft_) /
                capitalizationPeriod_;
            rate_ = (rate_ * rateLeft_) / PRECISION;
        }

        return rate_.min(_getMaxRate());
    }

    /**
     *  @notice The internal function to set the capitalization rate
     *  @param capitalizationRate_ new capitalization rate
     */
    function _setCapitalizationRate(uint256 capitalizationRate_) internal {
        _update();
        _changeCapitalizationRate(capitalizationRate_);
    }

    /**
     *  @notice The internal function to set the capitalization period
     *  @param capitalizationPeriod_ new capitalization period
     */
    function _setCapitalizationPeriod(uint64 capitalizationPeriod_) internal {
        _update();
        _changeCapitalizationPeriod(capitalizationPeriod_);
    }

    /**
     *  @notice The private function to update the compound rate
     */
    function _update() private {
        require(!isMaxRateReached, "CRK: max rate is reached");

        _currentRate = getCompoundRate();
        lastUpdate = uint64(block.timestamp);
    }

    /**
     *  @notice The private function that changes to capitalization rate
     */
    function _changeCapitalizationRate(uint256 capitalizationRate_) private {
        require(capitalizationRate_ >= PRECISION, "CRK: rate is less than 1");

        capitalizationRate = capitalizationRate_;

        emit CapitalizationRateChanged(capitalizationRate_);
    }

    /**
     *  @notice The private function that changes to capitalization period
     */
    function _changeCapitalizationPeriod(uint64 capitalizationPeriod_) private {
        require(capitalizationPeriod_ > 0, "CRK: invalid period");

        capitalizationPeriod = capitalizationPeriod_;

        emit CapitalizationPeriodChanged(capitalizationPeriod_);
    }

    /**
     *  @notice The private function to get the maximal possible compound rate
     */
    function _getMaxRate() private pure returns (uint256) {
        return type(uint128).max * PRECISION;
    }
}
