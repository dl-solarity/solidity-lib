// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PRECISION} from "../utils/Globals.sol";

abstract contract Vesting is Initializable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    event ScheduleCreated(uint256 indexed scheduleId);
    event VestingCreated(uint256 indexed vestingId, address beneficiary, address token);
    event WithdrawnFromVesting(uint256 indexed vestingId, uint256 amount);

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

    uint256 public scheduleId;
    uint256 public vestingId;

    // id => schedule
    mapping(uint256 => Schedule) private _schedules;
    // id => vesting
    mapping(uint256 => VestingData) private _vestings;
    // beneficiary => vesting ids
    mapping(address => EnumerableSet.UintSet) private _beneficiaryIds;

    function __Vesting_init() internal onlyInitializing {}

    function getSchedule(uint256 scheduleId_) public view virtual returns (Schedule memory) {
        return _schedules[scheduleId_];
    }

    function getVesting(uint256 vestingId_) public view virtual returns (VestingData memory) {
        return _vestings[vestingId_];
    }

    function getVestings(address beneficiary_) public view virtual returns (VestingData[] memory) {
        uint256[] memory ids_ = _beneficiaryIds[beneficiary_].values();
        VestingData[] memory beneficiaryVestings_ = new VestingData[](ids_.length);

        for (uint256 i = 0; i < ids_.length; i++) {
            beneficiaryVestings_[i] = _vestings[ids_[i]];
        }

        return beneficiaryVestings_;
    }

    function getVestingIds(address beneficiary_) public view virtual returns (uint256[] memory) {
        return _beneficiaryIds[beneficiary_].values();
    }

    function getVestedAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getVestedAmount(_vesting, _schedule, block.timestamp);
    }

    function getWithdrawableAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getWithdrawableAmount(_vesting, _schedule, block.timestamp);
    }

    function withdrawFromVesting(uint256 vestingId_) public virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only beneficiary can withdraw from his vesting"
        );
        require(_vesting.vestingAmount > 0, "VestingWallet: vesting amount is zero");
        require(
            _vesting.paidAmount < _vesting.vestingAmount,
            "VestingWallet: nothing to withdraw"
        );
        require(
            _vesting.vestingToken != address(0),
            "VestingWallet: vesting token is zero address"
        );

        uint256 amountToPay_ = getWithdrawableAmount(vestingId_);
        address token_ = _vesting.vestingToken;

        _vesting.paidAmount += amountToPay_;

        IERC20(token_).safeTransfer(msg.sender, amountToPay_);

        emit WithdrawnFromVesting(vestingId_, amountToPay_);
    }

    function _calculateElapsedPeriods(
        uint256 startTime_,
        uint256 timestampUpTo_,
        uint256 secondsInPeriod_
    ) internal pure returns (uint256) {
        return
            timestampUpTo_ > startTime_ ? (timestampUpTo_ - startTime_) / (secondsInPeriod_) : 0;
    }

    function _getVestedAmount(
        VestingData storage vesting,
        Schedule storage schedule,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule,
                vesting.vestingAmount,
                vesting.vestingStartTime,
                timestampUpTo_
            );
    }

    function _getWithdrawableAmount(
        VestingData storage vesting,
        Schedule storage schedule,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                schedule,
                vesting.vestingAmount,
                vesting.vestingStartTime,
                timestampUpTo_
            ) - vesting.paidAmount;
    }

    function _vestingCalculation(
        Schedule memory schedule_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256 vestedAmount_) {
        BaseSchedule memory baseData_ = schedule_.scheduleData;

        if (vestingStartTime_ > timestampUpTo_) return vestedAmount_;

        uint256 elapsedPeriods_ = _calculateElapsedPeriods(
            vestingStartTime_,
            timestampUpTo_,
            baseData_.secondsInPeriod
        );

        if (elapsedPeriods_ <= baseData_.cliffInPeriods) {
            return 0;
        }

        if (elapsedPeriods_ >= baseData_.durationInPeriods) {
            return totalVestingAmount_;
        }

        uint256 elapsedPeriodsPercentage_ = (elapsedPeriods_ * PRECISION) /
            baseData_.durationInPeriods;

        vestedAmount_ =
            (_raiseToPower(elapsedPeriodsPercentage_, schedule_.exponent) *
                (totalVestingAmount_)) /
            _raiseToPower(PRECISION, schedule_.exponent);

        return vestedAmount_.min(totalVestingAmount_);
    }

    function _createSchedule(
        BaseSchedule memory baseSchedule_
    ) internal virtual returns (uint256) {
        _validateSchedule(baseSchedule_);

        _schedules[++scheduleId] = Schedule({
            scheduleData: baseSchedule_,
            exponent: LINEAR_EXPONENT
        });

        return scheduleId;
    }

    function _createSchedule(Schedule memory schedule_) internal virtual returns (uint256) {
        require(
            schedule_.exponent > 0,
            "VestingWallet: cannot create schedule with zero exponent"
        );

        _validateSchedule(schedule_.scheduleData);

        _schedules[++scheduleId] = schedule_;

        emit ScheduleCreated(scheduleId);

        return scheduleId;
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
        require(
            vesting_.vestingToken != address(0),
            "VestingWallet: vesting token cannot be zero address"
        );

        Schedule storage _schedule = _schedules[vesting_.scheduleId];

        require(
            vesting_.vestingStartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for past date"
        );

        uint256 _currentVestingId = ++vestingId;

        _beneficiaryIds[vesting_.beneficiary].add(_currentVestingId);

        _vestings[_currentVestingId] = vesting_;

        emit VestingCreated(_currentVestingId, vesting_.beneficiary, vesting_.vestingToken);

        return _currentVestingId;
    }

    function _validateSchedule(BaseSchedule memory schedule_) private pure {
        require(
            schedule_.durationInPeriods > 0 && schedule_.secondsInPeriod > 0,
            "VestingWallet: cannot create schedule with zero duration or zero seconds in period"
        );
        require(
            schedule_.cliffInPeriods < schedule_.durationInPeriods,
            "VestingWallet: cliff cannot be greater than duration"
        );
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
