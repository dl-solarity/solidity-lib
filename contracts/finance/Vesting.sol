// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PRECISION} from "../utils/Globals.sol";

/**
 * @title Vesting
 * @notice The Abstract Vesting Contract serves as a robust module
 * designed to seamlessly manage vestings and associated schedules for
 * multiple beneficiaries and ERC20 tokens. This module stands out for its
 * flexibility, offering support for both linear and exponential vesting calculations out of the box.
 */
abstract contract Vesting is Initializable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice Struct defining the base schedule parameters.
     */
    struct BaseSchedule {
        uint256 secondsInPeriod;
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
    }

    /**
     * @notice Struct defining a vesting schedule, extending BaseSchedule.
     */
    struct Schedule {
        BaseSchedule scheduleData;
        uint256 exponent;
    }

    /**
     * @notice Struct defining vesting data for an individual beneficiary.
     */
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

    /**
     * @notice Emitted when a new schedule is created.
     * @param scheduleId The ID of the created schedule.
     */
    event ScheduleCreated(uint256 indexed scheduleId);

    /**
     * @notice Emitted when a new vesting contract is created.
     * @param vestingId The ID of the created vesting contract.
     * @param beneficiary The beneficiary of the vesting contract.
     * @param token The ERC20 token address used for the vesting.
     */
    event VestingCreated(uint256 indexed vestingId, address beneficiary, address token);

    /**
     * @notice Emitted when funds are withdrawn from a vesting contract.
     * @param vestingId The ID of the vesting contract from which funds are withdrawn.
     * @param amount The amount of funds withdrawn.
     */
    event WithdrawnFromVesting(uint256 indexed vestingId, uint256 amount);

    /**
     * @notice Constructor.
     */
    function __Vesting_init() internal onlyInitializing {}

    /**
     * @notice Withdraws funds from a vesting contract.
     * @param vestingId_ The ID of the vesting contract.
     */
    function withdrawFromVesting(uint256 vestingId_) public virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only beneficiary can withdraw from his vesting"
        );
        require(
            _vesting.paidAmount < _vesting.vestingAmount,
            "VestingWallet: nothing to withdraw"
        );

        uint256 amountToPay_ = getWithdrawableAmount(vestingId_);
        address token_ = _vesting.vestingToken;

        _vesting.paidAmount += amountToPay_;

        IERC20(token_).safeTransfer(msg.sender, amountToPay_);

        emit WithdrawnFromVesting(vestingId_, amountToPay_);
    }

    /**
     * @notice Retrieves a schedule by ID.
     * @param scheduleId_ The ID of the schedule to retrieve.
     * @return Schedule struct.
     */
    function getSchedule(uint256 scheduleId_) public view virtual returns (Schedule memory) {
        return _schedules[scheduleId_];
    }

    /**
     * @notice Retrieves vesting data by ID.
     * @param vestingId_ The ID of the vesting contract to retrieve.
     * @return VestingData struct.
     */
    function getVesting(uint256 vestingId_) public view virtual returns (VestingData memory) {
        return _vestings[vestingId_];
    }

    /**
     * @notice Retrieves all vesting data for a beneficiary.
     * @param beneficiary_ The address of the beneficiary.
     * @return An array of VestingData struct.
     */
    function getVestings(address beneficiary_) public view virtual returns (VestingData[] memory) {
        uint256[] memory ids_ = _beneficiaryIds[beneficiary_].values();
        VestingData[] memory beneficiaryVestings_ = new VestingData[](ids_.length);

        for (uint256 i = 0; i < ids_.length; i++) {
            beneficiaryVestings_[i] = _vestings[ids_[i]];
        }

        return beneficiaryVestings_;
    }

    /**
     * @notice Retrieves all vesting IDs for a beneficiary.
     * @param beneficiary_ The address of the beneficiary.
     * @return An array of uint256 representing all vesting IDs for the beneficiary.
     */
    function getVestingIds(address beneficiary_) public view virtual returns (uint256[] memory) {
        return _beneficiaryIds[beneficiary_].values();
    }

    /**
     * @notice Retrieves the vested amount for a vesting ID.
     * @param vestingId_ The ID of the vesting contract.
     * @return The amount of tokens vested.
     */
    function getVestedAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getVestedAmount(_vesting, _schedule, block.timestamp);
    }

    /**
     * @notice Retrieves the withdrawable amount for a vesting ID.
     * @param vestingId_ The ID of the vesting contract.
     * @return The amount of tokens available to withdraw.
     */
    function getWithdrawableAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];
        Schedule storage _schedule = _schedules[_vesting.scheduleId];

        return _getWithdrawableAmount(_vesting, _schedule, block.timestamp);
    }

    /**
     * @notice Creates a new vesting schedule.
     * @dev The exponent is set to 1, making the vesting linear.
     * @param baseSchedule_ Base schedule data for the new schedule.
     * @return The ID of the created schedule.
     */
    function _createSchedule(
        BaseSchedule memory baseSchedule_
    ) internal virtual returns (uint256) {
        _validateSchedule(baseSchedule_);

        _schedules[++scheduleId] = Schedule({
            scheduleData: baseSchedule_,
            exponent: LINEAR_EXPONENT
        });

        emit ScheduleCreated(scheduleId);

        return scheduleId;
    }

    /**
     * @notice Creates a new vesting schedule with a custom exponent.
     * @param schedule_ Schedule data for the new schedule.
     * @return The ID of the created schedule.
     */
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

    /**
     * @notice Creates a new vesting contract.
     * @param vesting_ Vesting data for the new contract.
     * @return The ID of the created vesting contract.
     */
    function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
        _validateVesting(vesting_);

        Schedule storage _schedule = _schedules[vesting_.scheduleId];

        require(
            vesting_.vestingStartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for a past date"
        );

        uint256 _currentVestingId = ++vestingId;

        _beneficiaryIds[vesting_.beneficiary].add(_currentVestingId);

        _vestings[_currentVestingId] = vesting_;

        emit VestingCreated(_currentVestingId, vesting_.beneficiary, vesting_.vestingToken);

        return _currentVestingId;
    }

    /**
     * @notice Retrieves the vested amount for a vesting ID.
     * @param vesting Vesting data for the vesting contract.
     * @param schedule Schedule data for the vesting contract.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return The amount of tokens vested.
     */
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

    /**
     * @notice Retrieves the withdrawable amount for a vesting ID.
     * @param vesting Vesting data for the vesting contract.
     * @param schedule Schedule data for the vesting contract.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return The amount of tokens withdrawable.
     */
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

    /**
     * @notice Performs the vesting calculation.
     * @param schedule_ Schedule data for the vesting contract.
     * @param totalVestingAmount_ The total amount of tokens to be vested.
     * @param vestingStartTime_ The starting time of the vesting.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return vestedAmount_ The amount of tokens vested.
     */
    function _vestingCalculation(
        Schedule memory schedule_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256 vestedAmount_) {
        BaseSchedule memory baseData_ = schedule_.scheduleData;

        if (vestingStartTime_ > timestampUpTo_) {
            return vestedAmount_;
        }

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

    /**
     * @notice Validates the base schedule parameters.
     * @param schedule_ Base schedule data to be validated.
     */
    function _validateSchedule(BaseSchedule memory schedule_) internal pure {
        require(
            schedule_.durationInPeriods > 0 && schedule_.secondsInPeriod > 0,
            "VestingWallet: cannot create schedule with zero duration or zero seconds in period"
        );
        require(
            schedule_.cliffInPeriods < schedule_.durationInPeriods,
            "VestingWallet: cliff cannot be greater than duration"
        );
    }

    /**
     * @notice Validates the vesting parameters.
     * @param vesting_ Vesting data to be validated.
     */
    function _validateVesting(VestingData memory vesting_) internal pure {
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
    }

    /**
     * @notice Calculates the elapsed periods.
     * @param startTime_ The starting time of the vesting.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @param secondsInPeriod_ The duration of each vesting period in seconds.
     * @return The number of elapsed periods.
     */
    function _calculateElapsedPeriods(
        uint256 startTime_,
        uint256 timestampUpTo_,
        uint256 secondsInPeriod_
    ) internal pure returns (uint256) {
        return
            timestampUpTo_ > startTime_ ? (timestampUpTo_ - startTime_) / (secondsInPeriod_) : 0;
    }

    /**
     * @notice Implementation of exponentiation by squaring with fixed precision.
     * @param base_ The base value.
     * @param exponent_ The exponent value.
     * @return result_ The result of the base raised to the exponent.
     */
    function _raiseToPower(
        uint256 base_,
        uint256 exponent_
    ) internal pure returns (uint256 result_) {
        result_ = exponent_ & 1 == 0 ? PRECISION : base_;

        while ((exponent_ >>= 1) > 0) {
            base_ = (base_ * base_) / PRECISION;

            if (exponent_ & 1 == 1) {
                result_ = (result_ * base_) / PRECISION;
            }
        }
    }
}
