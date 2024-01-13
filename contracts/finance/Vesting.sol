// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PRECISION} from "../utils/Globals.sol";

abstract contract VestingWallet is Initializable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // structure of vesting object
    struct VestingData {
        bool isActive;
        address beneficiary;
        uint256 totalAmount;
        uint256 paidAmount;
        bool isRevocable;
        string scheduleType;
    }

    // properties for linear vesting schedule
    struct Schedule {
        string scheduleType;
        uint256 startTimestamp;
        uint256 periodSeconds;
        uint256 cliffInPeriods;
        uint256 portionOfTotal;
        uint256 portionPerPeriod;
    }

    uint256 public _totalAmountInVestings;

    IERC20 public _vestingToken;
    VestingData[] public _vestings;

    EnumerableSet.Bytes32Set _scheduleTypes;

    mapping(bytes32 scheduleTypeHash => Schedule[]) public _schedulesByType;

    event VestingTokenSet(IERC20 token);
    event VestingScheduleAdded(string scheduleType);
    event VestingAdded(uint256 vestingId, address beneficiary);
    event VestingRevoked(uint256 vestingId);
    event VestingWithdraw(uint256 vestingId, uint256 amount);

    // initialization
    function __VestingWallet_init(Schedule[] memory schedules) internal onlyInitializing {
        _initializeVestingSchedules(schedules);
    }

    // get amount that is present on the contract but not allocated to vesting
    function getAvailableTokensAmount() public view virtual returns (uint256) {
        return _vestingToken.balanceOf(address(this)) - (_totalAmountInVestings);
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
        require(vestingId_ < _vestings.length, "VestingWallet: no vesting with such id");

        return _getVesting(vestingId_);
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

    // get vesting info
    function _getVesting(uint256 vestingId_) internal view virtual returns (VestingData storage) {
        return _vestings[vestingId_];
    }

    // calculate releasable amount at the moment
    function _calculateReleasedAmount(
        VestingData memory vesting_
    ) internal view virtual returns (uint256 _releasedAmount) {
        bytes32 _scheduleTypeHash = keccak256(bytes(vesting_.scheduleType));

        require(
            _scheduleTypes.contains(_scheduleTypeHash),
            "VestingWallet: schedule type does not exist"
        );

        Schedule[] storage _schedules = _schedulesByType[_scheduleTypeHash];

        for (uint256 i = 0; i < _schedules.length; i++) {
            Schedule storage _schedule = _schedules[i];

            if (_schedule.startTimestamp > block.timestamp) return _releasedAmount;

            uint256 _partOfReleasedAmount = _calculateLinearVestingAvailableAmount(
                _schedule,
                vesting_.totalAmount
            );

            _releasedAmount += _partOfReleasedAmount;
        }
    }

    // calculation of linear vesting
    function _calculateLinearVestingAvailableAmount(
        Schedule storage schedule_,
        uint256 amount_
    ) internal view virtual returns (uint256) {
        uint256 _elapsedPeriods = _calculateElapsedPeriods(schedule_);

        if (_elapsedPeriods <= schedule_.cliffInPeriods) return 0;

        // amount we should get after vesting
        uint256 _totalVestingAmount = (amount_ * schedule_.portionOfTotal) / (PRECISION);

        // amount we should get at the end of one period
        uint256 _amountPerPeriod = (_totalVestingAmount * schedule_.portionPerPeriod) /
            (PRECISION);

        return (_amountPerPeriod * _elapsedPeriods).min(_totalVestingAmount);
    }

    // calculate elapsed periods
    function _calculateElapsedPeriods(
        Schedule memory _linearVesting
    ) private view returns (uint256) {
        return (block.timestamp - _linearVesting.startTimestamp) / (_linearVesting.periodSeconds);
    }

    // initilizes default vesting schedules (here used as an example)
    function _initializeVestingSchedules(Schedule[] memory schedules) internal virtual {
        for (uint i = 0; i < schedules.length; i++) {
            _addVestingSchedule(schedules[i]);
        }
    }

    // set vesting token
    function _setVestingToken(IERC20 token_) internal virtual {
        require(address(token_) == address(0), "VestingWallet: token is already set");

        _vestingToken = token_;

        emit VestingTokenSet(token_);
    }

    // add vesting schedule with your own properties
    function _addVestingSchedule(Schedule memory schedule_) internal virtual {
        require(
            schedule_.startTimestamp + schedule_.periodSeconds > block.timestamp,
            "VestingWallet: final time is before current time"
        );

        bytes32 _scheduleTypeHash = keccak256(bytes(schedule_.scheduleType));

        if (!_scheduleTypes.contains(_scheduleTypeHash)) {
            _scheduleTypes.add(_scheduleTypeHash);
        }

        _schedulesByType[_scheduleTypeHash].push(schedule_);

        emit VestingScheduleAdded(schedule_.scheduleType);
    }

    // create vesting for multiple beneficiaries
    function _createVestingBulk(
        address[] calldata beneficiaries_,
        uint256[] calldata amounts_,
        string[] calldata scheduleTypes_,
        bool[] calldata isRevocable_
    ) internal virtual {
        require(
            beneficiaries_.length == amounts_.length &&
                beneficiaries_.length == scheduleTypes_.length &&
                beneficiaries_.length == isRevocable_.length,
            "VestingWallet: parameters length mismatch"
        );

        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            _createVesting(beneficiaries_[i], amounts_[i], scheduleTypes_[i], isRevocable_[i]);
        }
    }

    // create vesting
    function _createVesting(
        address beneficiary_,
        uint256 amount_,
        string memory scheduleType_,
        bool isRevocable_
    ) internal virtual returns (uint256 _vestingId) {
        require(
            _scheduleTypes.contains(keccak256(bytes(scheduleType_))),
            "VestingWallet: schedule type does not exist"
        );
        require(
            getAvailableTokensAmount() >= amount_,
            "VestingWallet: not enough tokens in vesting contract"
        );
        require(
            beneficiary_ != address(0),
            "VestingWallet: cannot create vesting for zero address"
        );
        require(
            beneficiary_ != address(0),
            "VestingWallet: cannot create vesting for zero address"
        );
        require(amount_ > 0, "VestingWallet: cannot create vesting for zero amount");

        _totalAmountInVestings += amount_;

        _vestingId = _vestings.length;

        _vestings.push(
            VestingData({
                isActive: true,
                beneficiary: beneficiary_,
                totalAmount: amount_,
                scheduleType: scheduleType_,
                paidAmount: 0,
                isRevocable: isRevocable_
            })
        );

        emit VestingAdded(_vestingId, beneficiary_);
    }

    // revoke vesting and release locked tokens
    function _revokeVesting(uint256 vestingId_) internal virtual {
        VestingData storage _vesting = _getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is revoked");
        require(_vesting.isRevocable, "VestingWallet: vesting is not revocable");

        _vesting.isActive = false;

        uint256 _amountReleased = _vesting.totalAmount - _vesting.paidAmount;
        _totalAmountInVestings -= _amountReleased;

        emit VestingRevoked(vestingId_);
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(uint256 vestingId_) internal virtual {
        VestingData storage _vesting = _getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is canceled");

        uint256 _amountToPay = _getWithdrawableAmount(_vesting);

        _vesting.paidAmount += _amountToPay;
        _totalAmountInVestings -= _amountToPay;

        _vestingToken.safeTransfer(_vesting.beneficiary, _amountToPay);

        emit VestingWithdraw(vestingId_, _amountToPay);
    }
}
