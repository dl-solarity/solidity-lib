// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {PRECISION} from "../utils/Globals.sol";

abstract contract Vesting is Initializable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    event ScheduleCreated(uint256 vestingId);
    event VestingCreated(uint256 vestingId);
    event WithdrawFromVesting(uint256 indexed vestingId, uint256 amount);

    struct BaseSchedule {
        uint256 secondsInPeriod;
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
    }

    struct Schedule {
        BaseSchedule scheduleData;
        uint256 exponent;
    }

    struct VestingData {
        uint256 vestingStartTime;
        address beneficiary;
        address vestingToken;
        uint256 vestingAmount;
        uint256 paidAmount;
        uint256 scheduleId;
    }

    uint256 public LINEAR_EXPONENT = 1;

    uint256 internal _scheduleId;
    uint256 internal _vestingId;

    mapping(uint256 id => Schedule) internal _schedules;
    mapping(uint256 id => VestingData) internal _vestings;
    mapping(address beneficiary => EnumerableSet.UintSet) internal _beneficiaryIds;

    // initialization
    function __Vesting_init() internal onlyInitializing {
        // for (uint256 i = 0; i < schedules_.length; i++) {
        //     _createSchedule(schedules_[i]);
        // }
    }

    function _createSchedule(Schedule memory schedule_) internal virtual returns (uint256) {
        _validateSchedule(schedule_.scheduleData);

        _schedules[++_scheduleId] = schedule_;

        emit ScheduleCreated(_scheduleId);

        return _scheduleId;
    }

    function _createSchedule(
        BaseSchedule memory baseSchedule_
    ) internal virtual returns (uint256) {
        _validateSchedule(baseSchedule_);

        _schedules[++_scheduleId] = Schedule({
            scheduleData: baseSchedule_,
            exponent: LINEAR_EXPONENT
        });

        return _scheduleId;
    }

    function _validateSchedule(BaseSchedule memory schedule_) internal pure virtual {
        require(
            schedule_.durationInPeriods > 0 && schedule_.secondsInPeriod > 0,
            "VestingWallet: cannot create schedule with zero duration or zero seconds in period"
        );
    }

    function getSchedule(uint256 scheduleId_) public view virtual returns (Schedule memory) {
        return _schedules[scheduleId_];
    }

    function getVesting(uint256 vestingId_) public view virtual returns (VestingData memory) {
        return _vestings[vestingId_];
    }

    // get vesting ids by beneficiary
    function getVestings(address beneficiary_) public view virtual returns (VestingData[] memory) {
        uint256[] memory _ids = _beneficiaryIds[beneficiary_].values();
        VestingData[] memory _beneficiaryVestings = new VestingData[](_ids.length);

        for (uint i = 0; i < _ids.length; i++) {
            _beneficiaryVestings[i] = _vestings[i];
        }

        return _beneficiaryVestings;
    }

    // get vesting ids by beneficiary
    function getVestingIds(address beneficiary_) public view virtual returns (uint256[] memory) {
        return _beneficiaryIds[beneficiary_].values();
    }

    // get available amount to withdraw
    function getWithdrawableAmount(
        uint256 vestingId_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getWithdrawableAmount(_vesting, _schedule, timestampUpTo_, timestampCurrent_);
    }

    // get vested amount at the moment
    function getVestedAmount(
        uint256 vestingId_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getVestedAmount(_vesting, _schedule, timestampUpTo_, timestampCurrent_);
    }

    // get available amount to withdraw
    function _getWithdrawableAmount(
        VestingData storage vesting_,
        Schedule storage schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule_,
                vesting_.vestingAmount,
                vesting_.vestingStartTime,
                timestampUpTo_,
                timestampCurrent_
            ) - vesting_.paidAmount;
    }

    // get released amount at the moment
    function _getVestedAmount(
        VestingData storage vesting_,
        Schedule storage schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule_,
                vesting_.vestingAmount,
                vesting_.vestingStartTime,
                timestampUpTo_,
                timestampCurrent_
            );
    }

    function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
        require(
            vesting_.vestingStartTime > 0,
            "VestingWallet: cannot create vesting for zero time"
        );
        require(
            vesting_.vestingAmount > 0,
            "VestingWallet: cannot create vesting for zero amount"
        );
        require(
            vesting_.beneficiary != address(0),
            "VestingWallet: cannot create vesting for zero address"
        );

        Schedule memory _schedule = _schedules[vesting_.scheduleId];

        require(
            vesting_.vestingStartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for past date"
        );

        _vestingId++;

        _beneficiaryIds[vesting_.beneficiary].add(_vestingId);

        _vestings[_vestingId] = vesting_;

        emit VestingCreated(_vestingId);

        return _vestingId;
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(
        uint256 vestingId_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal virtual returns (uint256 _amountToPay, address _token) {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only befeciary can withdraw from his vesting"
        );

        _amountToPay = getWithdrawableAmount(vestingId_, timestampUpTo_, timestampCurrent_);
        _token = _vesting.vestingToken;

        _vesting.paidAmount += _amountToPay;

        emit WithdrawFromVesting(vestingId_, _amountToPay);
    }

    // default implementation of vesting calculation
    function _vestingCalculation(
        Schedule memory schedule_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256 _vestedAmount) {
        BaseSchedule memory _baseData = schedule_.scheduleData;

        if (vestingStartTime_ > timestampCurrent_) return _vestedAmount;

        uint256 _elapsedPeriods = _calculateElapsedPeriods(
            vestingStartTime_,
            timestampUpTo_,
            _baseData.secondsInPeriod
        );

        if (_elapsedPeriods <= _baseData.cliffInPeriods) return 0;
        if (_elapsedPeriods >= _baseData.durationInPeriods) return totalVestingAmount_;

        uint256 _elapsedPeriodsPercentage = _elapsedPeriods.mulDiv(
            PRECISION,
            _baseData.durationInPeriods
        );

        _vestedAmount =
            (_elapsedPeriodsPercentage ** (schedule_.exponent) * (totalVestingAmount_)) /
            (PRECISION ** schedule_.exponent);

        return _vestedAmount.min(totalVestingAmount_);
    }

    // calculate elapsed periods
    function _calculateElapsedPeriods(
        uint256 startTime_,
        uint256 timestampUpTo_,
        uint256 secondsInPeriod_
    ) internal view virtual returns (uint256) {
        return
            timestampUpTo_ > startTime_ ? (timestampUpTo_ - startTime_) / (secondsInPeriod_) : 0;
    }
}
