// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {IVesting} from "./IVesting.sol";
import {ISchedule} from "./ScheduleModules/ISchedule.sol";

import {StringSet} from "../libs/data-structures/StringSet.sol";
import {PRECISION} from "../utils/Globals.sol";

abstract contract VestingWallet is IVesting, Initializable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using StringSet for StringSet.Set;
    using Counters for Counters.Counter;

    // structure of vesting object needed for creation
    struct CreateVestingData {
        address beneficiary;
        uint256 totalAmount;
        string scheduleType;
        bool isRevocable;
    }

    // properties for creating vesting schedule
    struct CreateSchedule {
        string scheduleType;
        ISchedule.Schedule baseInfo;
    }

    uint256 public totalAmountInVestings;
    IERC20 public vestingToken;

    Counters.Counter internal _counter;

    mapping(uint256 id => VestingData) internal _vestings;
    mapping(address beneficiary => EnumerableSet.UintSet) internal _beneficiaryIds;

    StringSet.Set internal _scheduleTypes;
    mapping(string scheduleType => ISchedule.Schedule) internal _scheduleByType;
    mapping(string scheduleType => ISchedule.Schedule) internal _scheduleByAddress;

    event VestingTokenSet(IERC20 token);
    event VestingScheduleAdded(string scheduleType);
    event VestingAdded(uint256 vestingId, address beneficiary);
    event VestingRevoked(uint256 vestingId);
    event VestingWithdraw(uint256 vestingId, uint256 amount);

    // initialization
    function __VestingWallet_init(CreateSchedule[] memory schedules) internal onlyInitializing {
        _initializeVestingSchedules(schedules);
    }

    // initilizes default vesting schedules (here used as an example)
    function _initializeVestingSchedules(CreateSchedule[] memory schedules) internal virtual {
        for (uint i = 0; i < schedules.length; i++) {
            _addVestingSchedule(schedules[i]);
        }
    }

    // add vesting schedule with your own properties
    function _addVestingSchedule(CreateSchedule memory schedule_) internal virtual {
        require(
            schedule_.baseInfo.startTimestamp + schedule_.baseInfo.periodSeconds > block.timestamp,
            "VestingWallet: final time is before current time"
        );

        string memory scheduleType = schedule_.scheduleType;

        require(bytes(scheduleType).length > 0, "VestingWallet: type can not be empty");

        _scheduleTypes.add(scheduleType);
        _scheduleByType[scheduleType] = schedule_.baseInfo;

        emit VestingScheduleAdded(scheduleType);
    }

    // get amount that is present on the contract but not allocated to vesting
    function getAvailableTokensAmount() public view virtual returns (uint256) {
        return vestingToken.balanceOf(address(this)) - (totalAmountInVestings);
    }

    // get available amount to withdraw
    function getWithdrawableAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData memory _vesting = getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is canceled");

        return _getWithdrawableAmount(_vesting);
    }

    // get released amount at the moment
    function getReleasedAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData memory _vesting = getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is canceled");

        return _getReleasedAmount(_vesting);
    }

    // get vesting info by vesting id
    function getVesting(uint256 vestingId_) public view virtual returns (VestingData memory) {
        return _vestings[vestingId_];
    }

    // get vesting ids by beneficiary
    function getVestingIds(address beneficiary_) public view virtual returns (uint256[] memory) {
        return _beneficiaryIds[beneficiary_].values();
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

    // get available amount to withdraw
    function _getWithdrawableAmount(
        VestingData memory _vesting
    ) internal view virtual returns (uint256) {
        return _calculateReleasedAmount(_vesting) - _vesting.paidAmount;
    }

    // get released amount at the moment
    function _getReleasedAmount(
        VestingData memory _vesting
    ) internal view virtual returns (uint256) {
        return _calculateReleasedAmount(_vesting);
    }

    // calculate released amount at the moment
    function _calculateReleasedAmount(
        VestingData memory vesting_
    ) internal view virtual returns (uint256 _releasedAmount) {
        require(
            _scheduleTypes.contains(vesting_.scheduleType),
            "VestingWallet: schedule type does not exist"
        );

        ISchedule.Schedule storage _schedule = _scheduleByType[vesting_.scheduleType];

        if (_schedule.startTimestamp > block.timestamp) return _releasedAmount;

        //_releasedAmount = calculate(_schedule, vesting_.totalAmount);
    }

    // set vesting token
    function _setVestingToken(IERC20 token_) internal virtual {
        require(address(token_) == address(0), "VestingWallet: token is already set");

        vestingToken = token_;

        emit VestingTokenSet(token_);
    }

    // create vesting for multiple beneficiaries
    function _createVestingBulk(CreateVestingData[] calldata vestings_) internal virtual {
        for (uint256 i = 0; i < vestings_.length; i++) {
            _createVesting(vestings_[i]);
        }
    }

    // create vesting
    function _createVesting(
        CreateVestingData memory vesting_
    ) internal virtual returns (uint256 _vestingId) {
        require(vesting_.totalAmount > 0, "VestingWallet: cannot create vesting for zero amount");
        require(
            getAvailableTokensAmount() >= vesting_.totalAmount,
            "VestingWallet: not enough tokens in vesting contract"
        );
        require(
            _scheduleTypes.contains(vesting_.scheduleType),
            "VestingWallet: schedule type does not exist"
        );
        require(
            vesting_.beneficiary != address(0),
            "VestingWallet: cannot create vesting for zero address"
        );

        totalAmountInVestings += vesting_.totalAmount;

        _counter.increment();

        _beneficiaryIds[vesting_.beneficiary].add(_counter.current());

        _vestings[_counter.current()] = VestingData({
            isActive: true,
            beneficiary: vesting_.beneficiary,
            totalAmount: vesting_.totalAmount,
            scheduleType: vesting_.scheduleType,
            paidAmount: 0,
            isRevocable: vesting_.isRevocable
        });

        emit VestingAdded(_vestingId, vesting_.beneficiary);
    }

    // revoke vesting and release locked tokens
    function _revokeVesting(uint256 vestingId_) internal virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        require(_vesting.isActive, "VestingWallet: vesting is revoked");
        require(_vesting.isRevocable, "VestingWallet: vesting is not revocable");

        _vesting.isActive = false;

        uint256 _amountReleased = _vesting.totalAmount - _vesting.paidAmount;
        totalAmountInVestings -= _amountReleased;

        emit VestingRevoked(vestingId_);
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(uint256 vestingId_) internal virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        require(
            msg.sender == _vesting.beneficiary,
            "VestingWallet: only befeciary can withdraw from his vesting"
        );
        require(_vesting.isActive, "VestingWallet: vesting is revoked");

        uint256 _amountToPay = _getWithdrawableAmount(_vesting);

        _vesting.paidAmount += _amountToPay;
        totalAmountInVestings -= _amountToPay;

        vestingToken.safeTransfer(_vesting.beneficiary, _amountToPay);

        emit VestingWithdraw(vestingId_, _amountToPay);
    }
}
