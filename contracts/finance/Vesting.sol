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

    event ScheduleCreated(uint256 indexed vestingId);
    event VestingCreated(uint256 indexed vestingId);
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

    uint256 public constant LINEAR_EXPONENT = 1;

    uint256 internal _scheduleId;
    uint256 internal _vestingId;

    // id => schedule
    mapping(uint256 => Schedule) internal _schedules;
    // id => vesting
    mapping(uint256 => VestingData) internal _vestings;
    // beneficiary => vesting ids
    mapping(address => EnumerableSet.UintSet) internal _beneficiaryIds;

    // initialization
    function __Vesting_init() internal onlyInitializing {}

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
    function getWithdrawableAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getWithdrawableAmount(_vesting, _schedule, block.timestamp);
    }

    // get vested amount at the moment
    function getVestedAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getVestedAmount(_vesting, _schedule, block.timestamp);
    }

    // get available amount to withdraw
    function _getWithdrawableAmount(
        VestingData storage vesting_,
        Schedule storage schedule_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule_,
                vesting_.vestingAmount,
                vesting_.vestingStartTime,
                timestampUpTo_,
                block.timestamp
            ) - vesting_.paidAmount;
    }

    // get released amount at the moment
    function _getVestedAmount(
        VestingData storage vesting_,
        Schedule storage schedule_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule_,
                vesting_.vestingAmount,
                vesting_.vestingStartTime,
                timestampUpTo_,
                block.timestamp
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
            _schedule.scheduleData.cliffInPeriods < _schedule.scheduleData.durationInPeriods,
            "VestingWallet: cliff cannot be greater than duration"
        );

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
        uint256 vestingId_
    ) internal virtual returns (uint256 _amountToPay, address _token) {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only befeciary can withdraw from his vesting"
        );

        _amountToPay = getWithdrawableAmount(vestingId_);
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

        if (_elapsedPeriods <= _baseData.cliffInPeriods) {
            return 0;
        }
        if (_elapsedPeriods >= _baseData.durationInPeriods) {
            return totalVestingAmount_;
        }

        uint256 _elapsedPeriodsPercentage = (_elapsedPeriods * PRECISION) /
            _baseData.durationInPeriods;

        _vestedAmount =
            (_raiseToPower(_elapsedPeriodsPercentage, schedule_.exponent) *
                (totalVestingAmount_)) /
            _raiseToPower(PRECISION, schedule_.exponent);

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

    function _raiseToPower(
        uint256 base_,
        uint256 exponent_
    ) private pure returns (uint256 result_) {
        result_ = exponent_ & 1 == 0 ? PRECISION : base_;

        while ((exponent_ >>= 1) > 0) {
            base_ = (base_ * base_) / PRECISION;

            if (exponent_ & 1 == 1) {
                result_ = (result_ * base_) / PRECISION;
            }
        }
    }
}
