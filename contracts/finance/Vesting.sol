// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

abstract contract VestingWallet is Initializable, OwnableUpgradeable {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    // examples of vesting types
    enum VestingScheduleType {
        VAULT
        // ANGELROUND,
        // SEEDROUND,
        // PRIVATEROUND,
        // LISTINGS,
        // GROWTH,
        // OPERATIONAL,
        // FOUNDERS,
        // DEVELOPERS,
        // BUGFINDING,
    }

    // structure of vesting object
    struct Vesting {
        bool isActive;
        address beneficiary;
        uint256 totalAmount;
        VestingScheduleType vestingScheduleType;
        uint256 paidAmount;
        bool isRevocable;
    }

    // properties for linear vesting schedule
    struct LinearVestingSchedule {
        uint256 portionOfTotal;
        uint256 startDate;
        uint256 periodInSeconds;
        uint256 portionPerPeriod;
        uint256 cliffInPeriods;
    }

    uint256 public constant SECONDS_IN_MONTH = 60 * 60 * 24 * 30;
    uint256 public constant PORTION_OF_TOTAL_PRECISION = 10 ** 10;
    uint256 public constant PORTION_PER_PERIOD_PRECISION = 10 ** 10;

    uint256 public _activationTimestamp;

    IERC20 public _vestingToken;

    Vesting[] public _vestings;
    uint256 public _amountInVestings;
    mapping(VestingScheduleType => LinearVestingSchedule[]) public _vestingSchedules;

    event VestingTokenSet(IERC20 token);
    event VestingAdded(uint256 vestingId, address beneficiary);
    event VestingRevoked(uint256 vestingId);
    event VestingWithdraw(uint256 vestingId, uint256 amount);

    // initialization
    function __VestingWallet_init(uint256 activationTimestamp_) internal onlyInitializing {
        __Ownable_init();

        _activationTimestamp = activationTimestamp_;

        _initializeVestingSchedules();
    }

    // get available amount to withdraw
    function getWithdrawableAmount(uint256 vestingId_) external view virtual returns (uint256) {
        Vesting memory _vesting = getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is canceled");

        return _getWithdrawableAmount(_vesting);
    }

    // withdraw available tokens from multiple vestings
    function withdrawFromVestingBulk(uint256 offset_, uint256 limit_) external virtual {
        uint256 _to = (offset_ + limit_).min(_vestings.length).max(offset_);

        for (uint256 i = offset_; i < _to; i++) {
            Vesting storage vesting = _getVesting(i);
            if (vesting.isActive) {
                _withdrawFromVesting(vesting, i);
            }
        }
    }

    // withdraw available tokens from vesting
    function withdrawFromVesting(uint256 vestingId_) external virtual {
        Vesting storage _vesting = _getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is canceled");

        _withdrawFromVesting(_vesting, vestingId_);
    }

    // get vesting info by vesting id
    function getVesting(uint256 vestingId_) public view virtual returns (Vesting memory) {
        return _getVesting(vestingId_);
    }

    // get amount that is present on the contract but not allocated to vesting
    function getAvailableTokensAmount() public view virtual returns (uint256) {
        return _vestingToken.balanceOf(address(this)) - (_amountInVestings);
    }

    // initilizes default vesting schedules (here used as an example)
    function _initializeVestingSchedules() internal virtual {
        _addLinearVestingSchedule(
            VestingScheduleType.VAULT,
            LinearVestingSchedule({
                portionOfTotal: PORTION_OF_TOTAL_PRECISION,
                startDate: _activationTimestamp,
                periodInSeconds: SECONDS_IN_MONTH,
                portionPerPeriod: PORTION_PER_PERIOD_PRECISION / 2,
                cliffInPeriods: 1
            })
        );
    }

    // add linear vesting schedule with your own properties
    function _addLinearVestingSchedule(
        VestingScheduleType type_,
        LinearVestingSchedule memory schedule_
    ) internal virtual onlyOwner {
        _vestingSchedules[type_].push(schedule_);
    }

    // set vesting token
    function _setVestingToken(IERC20 token_) internal virtual onlyOwner {
        require(address(token_) == address(0), "VestingWallet: token is already set");

        _vestingToken = token_;

        emit VestingTokenSet(token_);
    }

    // create vesting for multiple beneficiaries
    function _createVestingBulk(
        address[] calldata beneficiaries_,
        uint256[] calldata amounts_,
        VestingScheduleType[] calldata vestingSchedules_,
        bool[] calldata isRevokable_
    ) internal virtual onlyOwner {
        require(
            beneficiaries_.length == amounts_.length &&
                beneficiaries_.length == vestingSchedules_.length &&
                beneficiaries_.length == isRevokable_.length,
            "VestingWallet: parameters length mismatch"
        );

        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            _createVesting(beneficiaries_[i], amounts_[i], vestingSchedules_[i], isRevokable_[i]);
        }
    }

    // create vesting
    function _createVesting(
        address beneficiary_,
        uint256 amount_,
        VestingScheduleType vestingSchedule_,
        bool isRevokable_
    ) internal virtual onlyOwner returns (uint256 _vestingId) {
        require(
            getAvailableTokensAmount() >= amount_,
            "VestingWallet: not enough tokens in vesting contract"
        );
        require(
            beneficiary_ != address(0),
            "VestingWallet: cannot create vesting for zero address"
        );
        require(amount_ > 0, "VestingWallet: cannot create vesting for zero amount");

        _amountInVestings += amount_;

        _vestingId = _vestings.length;

        _vestings.push(
            Vesting({
                isActive: true,
                beneficiary: beneficiary_,
                totalAmount: amount_,
                vestingScheduleType: vestingSchedule_,
                paidAmount: 0,
                isRevocable: isRevokable_
            })
        );

        emit VestingAdded(_vestingId, beneficiary_);
    }

    // revoke vesting and release locked tokens
    function _revokeVesting(uint256 vestingId_) internal virtual onlyOwner {
        Vesting storage _vesting = _getVesting(vestingId_);

        require(_vesting.isActive, "VestingWallet: vesting is revoked");
        require(_vesting.isRevocable, "VestingWallet: vesting is not revokable");

        _vesting.isActive = false;

        uint256 _amountReleased = _vesting.totalAmount - _vesting.paidAmount;
        _amountInVestings -= _amountReleased;

        emit VestingRevoked(vestingId_);
    }

    // withdraw tokens from vesting and transfer to beneficiary
    function _withdrawFromVesting(Vesting storage vesting_, uint256 vestingId_) internal virtual {
        uint256 _amountToPay = _getWithdrawableAmount(vesting_);

        vesting_.paidAmount += _amountToPay;
        _amountInVestings -= _amountToPay;

        _vestingToken.safeTransfer(vesting_.beneficiary, _amountToPay);

        emit VestingWithdraw(vestingId_, _amountToPay);
    }

    // get available amount to withdraw
    function _getWithdrawableAmount(
        Vesting memory _vesting
    ) internal view virtual returns (uint256) {
        return _calculateReleasableAmount(_vesting) - _vesting.paidAmount;
    }

    // calculate releasable amount at the moment
    function _calculateReleasableAmount(
        Vesting memory vesting_
    ) internal view virtual returns (uint256) {
        LinearVestingSchedule[] storage _vestingSchedulesByType = _vestingSchedules[
            vesting_.vestingScheduleType
        ];

        uint256 _releasableAmount;

        for (uint256 i = 0; i < _vestingSchedulesByType.length; i++) {
            LinearVestingSchedule storage _vestingSchedule = _vestingSchedulesByType[i];

            if (_vestingSchedule.startDate > block.timestamp) return _releasableAmount;

            uint256 _releasableAmountForThisSchedule = _calculateLinearVestingAvailableAmount(
                _vestingSchedule,
                vesting_.totalAmount
            );

            _releasableAmount += _releasableAmountForThisSchedule;
        }

        return _releasableAmount;
    }

    // calculation of linear vesting
    function _calculateLinearVestingAvailableAmount(
        LinearVestingSchedule storage vestingSchedule_,
        uint256 amount_
    ) internal view virtual returns (uint256) {
        uint256 _elapsedPeriods = _calculateElapsedPeriods(vestingSchedule_);

        if (_elapsedPeriods <= vestingSchedule_.cliffInPeriods) return 0;

        uint256 _amountThisVestingSchedule = (amount_ * vestingSchedule_.portionOfTotal) /
            (PORTION_OF_TOTAL_PRECISION);

        uint256 _amountPerPeriod = (_amountThisVestingSchedule *
            vestingSchedule_.portionPerPeriod) / (PORTION_PER_PERIOD_PRECISION);

        return (_amountPerPeriod * _elapsedPeriods).min(_amountThisVestingSchedule);
    }

    // withdraw tokens that is present on the contract but not allocated to vesting
    function _withdrawExcessiveTokens() internal virtual onlyOwner {
        _vestingToken.safeTransfer(owner(), getAvailableTokensAmount());
    }

    // get vesting info
    function _getVesting(uint256 _vestingId) internal view virtual returns (Vesting storage) {
        require(_vestingId < _vestings.length, "VestingWallet: no vesting with such id");

        return _vestings[_vestingId];
    }

    // calculate elapsed periods
    function _calculateElapsedPeriods(
        LinearVestingSchedule storage _linearVesting
    ) private view returns (uint256) {
        return (block.timestamp - _linearVesting.startDate) / (_linearVesting.periodInSeconds);
    }
}
