// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {PRECISION} from "../utils/Globals.sol";

abstract contract VestingWallet is Initializable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct Schedule {
        uint256 startTime;
        uint256 secondsInPeriod;
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
        uint256 allocationPercentagePerPeriod;
        uint256 allocationPercentagePerVestingAmount;
    }

    struct BaseVesting {
        address beneficiary;
        address vestingToken;
        uint256 vestingAmount;
        uint256 paidAmount;
        uint256 scheduleId;
    }

    struct Vesting {
        BaseVesting vestingData;
        // function that will calculate vested amount
        // schedule, total vesting amount, timestamp up to, timestamp current
        function(Schedule memory, uint256, uint256, uint256)
            internal
            view
            returns (uint256) calculate;
    }

    Counters.Counter internal _vestingIds;
    Counters.Counter internal _scheduleIds;

    mapping(uint256 id => Vesting) internal _vestings;
    mapping(uint256 id => Schedule) internal _schedules;
    mapping(address beneficiary => EnumerableSet.UintSet) internal _beneficiaryIds;

    // initialization
    function __VestingWallet_init(Schedule[] memory schedules_) internal onlyInitializing {
        for (uint i = 0; i < schedules_.length; i++) {
            _createSchedule(schedules_[i]);
        }
    }

    function _createSchedule(
        Schedule memory schedule_
    ) internal virtual returns (uint256 _scheduleId) {
        require(
            schedule_.startTime + schedule_.durationInPeriods * schedule_.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for past date"
        );

        _scheduleIds.increment();
        _scheduleId = _scheduleIds.current();

        _schedules[_scheduleId] = schedule_;
    }

    function getSchedule(uint256 scheduleId_) public view virtual returns (Schedule memory) {
        return _schedules[scheduleId_];
    }

    function getVesting(uint256 vestingId_) public view virtual returns (BaseVesting memory) {
        return _vestings[vestingId_].vestingData;
    }

    // get vesting ids by beneficiary
    function getVestings(address beneficiary_) public view virtual returns (BaseVesting[] memory) {
        uint256[] memory _ids = _beneficiaryIds[beneficiary_].values();
        BaseVesting[] memory _beneficiaryVestings = new BaseVesting[](_ids.length);

        for (uint i = 0; i < _ids.length; i++) {
            _beneficiaryVestings[i] = _vestings[i].vestingData;
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
        Vesting memory _vesting = _vestings[vestingId_];
        Schedule memory _schedule = _schedules[_vesting.vestingData.scheduleId];

        return _getWithdrawableAmount(_vesting, _schedule, timestampUpTo_, timestampCurrent_);
    }

    // get vested amount at the moment
    function getVestedAmount(
        uint256 vestingId_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) public view virtual returns (uint256) {
        Vesting memory _vesting = _vestings[vestingId_];
        Schedule memory _schedule = _schedules[_vesting.vestingData.scheduleId];

        return _getVestedAmount(_vesting, _schedule, timestampUpTo_, timestampCurrent_);
    }

    // get available amount to withdraw
    function _getWithdrawableAmount(
        Vesting memory vesting_,
        Schedule memory schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            vesting_.calculate(
                schedule_,
                vesting_.vestingData.vestingAmount,
                timestampUpTo_,
                timestampCurrent_
            ) - vesting_.vestingData.paidAmount;
    }

    // get released amount at the moment
    function _getVestedAmount(
        Vesting memory vesting_,
        Schedule memory schedule_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256) {
        return
            vesting_.calculate(
                schedule_,
                vesting_.vestingData.vestingAmount,
                timestampUpTo_,
                timestampCurrent_
            );
    }

    function _createVesting(
        BaseVesting memory vesting_
    ) internal virtual returns (uint256 _vestingId) {
        _prepareVestingForCreation(vesting_);

        _vestingId = _vestingIds.current();

        _vestings[_vestingId] = Vesting({vestingData: vesting_, calculate: _vestingCalculation});
    }

    function _createVesting(
        Vesting memory vesting_
    ) internal virtual returns (uint256 _vestingId) {
        _prepareVestingForCreation(vesting_.vestingData);

        _vestingId = _vestingIds.current();

        _vestings[_vestingId] = vesting_;
    }

    // create vesting
    function _prepareVestingForCreation(BaseVesting memory vesting_) internal virtual {
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
            _schedule.startTime + _schedule.durationInPeriods * _schedule.secondsInPeriod >
                block.timestamp,
            "VestingWallet: cannot create vesting for past date"
        );

        _vestingIds.increment();

        _beneficiaryIds[vesting_.beneficiary].add(_vestingIds.current());

        _vestings[_vestingIds.current()] = Vesting({
            vestingData: vesting_,
            calculate: _vestingCalculation
        });

        // IERC20(vesting_.vestingToken).safeTransferFrom(
        //     _vesting.vestingData.beneficiary,
        //     address(this),
        //     vesting_.vestingAmount
        // );
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(uint256 vestingId_) internal virtual {
        Vesting storage _vesting = _vestings[vestingId_];
        Schedule memory _schedule = _schedules[_vesting.vestingData.scheduleId];

        require(
            msg.sender == _vesting.vestingData.beneficiary,
            "VestingWallet: only befeciary can withdraw from his vesting"
        );

        uint256 _amountToPay = _getWithdrawableAmount(
            _vesting,
            _schedule,
            _schedule.startTime,
            block.timestamp
        );

        _vesting.vestingData.paidAmount += _amountToPay;

        // IERC20(_vesting.vestingData.vestingToken).safeTransfer(
        //     _vesting.vestingData.beneficiary,
        //     _amountToPay
        // );
    }

    // default implementation of vesting calculation
    function _vestingCalculation(
        Schedule memory schedule_,
        uint256 vestingAmount_,
        uint256 timestampUpTo_,
        uint256 timestampCurrent_
    ) internal view virtual returns (uint256 _vestedAmount) {
        if (schedule_.startTime > timestampCurrent_) return _vestedAmount;

        uint256 _elapsedPeriods = _calculateElapsedPeriods(schedule_, timestampUpTo_);

        if (_elapsedPeriods <= schedule_.cliffInPeriods) return 0;

        // amount we should get after vesting
        uint256 _availableVestingAmount = (vestingAmount_ *
            schedule_.allocationPercentagePerVestingAmount) / (PRECISION);

        // amount we should get at the end of one period
        uint256 _amountPerPeriod = (_availableVestingAmount *
            schedule_.allocationPercentagePerPeriod) / (PRECISION);

        _vestedAmount = (_amountPerPeriod * _elapsedPeriods).min(_availableVestingAmount);
    }

    // calculate elapsed periods
    function _calculateElapsedPeriods(
        Schedule memory schedule_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            timestampUpTo_ > schedule_.startTime
                ? (timestampUpTo_ - schedule_.startTime) / (schedule_.secondsInPeriod)
                : 0;
    }
}
