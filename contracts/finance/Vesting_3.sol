// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    struct BaseSchedule {
        uint256 secondsInPeriod;
        uint256 totalDurationInPeriods;
        uint256 cliffInPeriods;
    }

    struct DynamicSegment {
        uint256 deltaInPeriods;
        uint256 segmentPercentage;
        uint256 exponent;
    }

    struct LinearSegment {
        uint256 segmentDurationInPeriods;
        uint256 percentage;
    }

    struct DynamicSchedule {
        BaseSchedule baseSchedule;
        DynamicSegment[] segments;
    }

    struct LinearSchedule {
        BaseSchedule baseSchedule;
        LinearSegment[] segments;
    }

    struct DynamicScheduleWithAlgorithm {
        DynamicSchedule schedule;
        function(DynamicSchedule[] memory, uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256) calculate;
    }

    struct LinearScheduleWithAlgorithm {
        LinearSchedule schedule;
        function(LinearSegment[] memory, uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256) calculate;
    }

    struct VestingData {
        uint256 vestingstartTime;
        address beneficiary;
        address vestingToken;
        uint256 vestingAmount;
        uint256 paidAmount;
        uint256 scheduleId;
    }

    uint256 internal _scheduleId;
    uint256 internal _vestingId;

    mapping(uint256 id => DynamicScheduleWithAlgorithm) internal _schedules;
    mapping(uint256 id => VestingData) internal _vestings;
    mapping(address beneficiary => EnumerableSet.UintSet) internal _beneficiaryIds;

    // initialization
    function __Vesting_init() internal onlyInitializing {}

    function _createSchedule(
        DynamicScheduleWithAlgorithm memory scheduleData_
    ) internal virtual returns (uint256) {
        _validateSchedule(scheduleData_);

        _schedules[++_scheduleId] = scheduleData_;

        return _scheduleId;
    }

    function _createSchedule(
        DynamicSchedule memory scheduleData_
    ) internal virtual returns (uint256) {
        _validateSchedule(scheduleData_);

        _schedules[++_scheduleId] = DynamicScheduleWithAlgorithm({
            schedule: scheduleData_,
            calculate: _vestingCalculation
        });

        return _scheduleId;
    }

    function _createSchedule(
        LinearScheduleWithAlgorithm memory scheduleData_
    ) internal virtual returns (uint256) {
        _validateSchedule(scheduleData_);

        _schedules[++_scheduleId] = DynamicScheduleWithAlgorithm({
            schedule: DynamicSchedule({
                baseSchedule: scheduleData_.schedule.baseSchedule,
                segments: _convertLinearToDynamic(scheduleData_.schedule.segments)
            }),
            calculate: scheduleData_.calculate
        });

        return _scheduleId;
    }

    function _createSchedule(
        LinearSchedule memory scheduleData_
    ) internal virtual returns (uint256) {
        _validateSchedule(scheduleData_);

        _schedules[++_scheduleId] = DynamicScheduleWithAlgorithm({
            schedule: DynamicSchedule({
                baseSchedule: scheduleData_.baseSchedule,
                segments: _convertLinearToDynamic(scheduleData_.segments)
            }),
            calculate: _vestingCalculation
        });

        return _scheduleId;
    }

    function _convertLinearSegmentsToDynamic(
        LinearSegment[] memory segments_
    ) internal pure returns (DynamicSegment[] memory) {
        _dynamicSegments = new DynamicSegment[](segments_.length);

        for (uint i = 0; i < _dynamicSegments.length; i++) {}
        _dynamicSegments[i] = DynamicSegment({
            deltaInPeriods: segments_.segmentDurationInPeriods,
            segmentPercentage: segments_.percentage,
            exponent: 1
        });

        return _dynamicSegments;
    }

    function _validateSchedule(DynamicSchedule memory schedule_) internal pure virtual {
        require(
            schedule_.durationInPeriods > 0 && schedule_.secondsInPeriod > 0,
            "VestingWallet: cannot create schedule with zero duration or zero seconds in period"
        );
    }

    function _validateSchedule(LinearSchedule memory schedule_) internal pure virtual {
        require(
            schedule_.durationInPeriods > 0 && schedule_.secondsInPeriod > 0,
            "VestingWallet: cannot create schedule with zero duration or zero seconds in period"
        );
    }

    function getSchedule(uint256 scheduleId_) public view virtual returns (BaseSchedule memory) {
        return _schedules[scheduleId_].scheduleData;
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
        VestingData memory vesting_,
        Schedule memory schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            schedule_.calculate(
                schedule_.scheduleData,
                vesting_.vestingAmount,
                vesting_.vestingstartTime,
                timestampUpTo_,
                timestampCurrent_
            ) - vesting_.paidAmount;
    }

    // get released amount at the moment
    function _getVestedAmount(
        VestingData memory vesting_,
        Schedule memory schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            schedule_.calculate(
                schedule_.scheduleData,
                vesting_.vestingAmount,
                vesting_.vestingstartTime,
                timestampUpTo_,
                timestampCurrent_
            );
    }

    function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
        require(
            vesting_.vestingstartTime > 0,
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
            vesting_.vestingstartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for past date"
        );

        _vestingId++;

        _beneficiaryIds[vesting_.beneficiary].add(_vestingId);

        _vestings[_vestingId] = vesting_;

        return _vestingId;
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(
        uint256 vestingId_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only befeciary can withdraw from his vesting"
        );

        uint256 _amountToPay = getWithdrawableAmount(
            vestingId_,
            timestampUpTo_,
            timestampCurrent_
        );

        _vesting.paidAmount += _amountToPay;
    }

    // default implementation of vesting calculation
    function _vestingCalculation(
        BaseSchedule memory schedule_,
        uint256 vestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256 _vestedAmount) {
        if (vestingStartTime_ > timestampCurrent_) return _vestedAmount;

        uint256 _elapsedPeriods = _calculateElapsedPeriods(
            vestingStartTime_,
            timestampUpTo_,
            schedule_.secondsInPeriod
        );

        if (_elapsedPeriods <= schedule_.cliffInPeriods) return 0;

        // amount we should get at the end of one period
        uint256 _amountPerPeriod = (vestingAmount_ * schedule_.segment) / (PRECISION);

        _vestedAmount = (_amountPerPeriod * _elapsedPeriods).min(vestingAmount_);
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
