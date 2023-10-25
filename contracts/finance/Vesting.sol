// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "../libs/arrays/SetHelper.sol";

// should we move revoke to a separate contract as extension/preset
// should we allow the owner of the contract configure cliff
// should we make this contract ownable or make it as a separate preset
// add additional exetenstions with different formula of vesting (linear, exponential, etc)
abstract contract VestingWallet is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event BeneficiaryAdded(address account, uint256 shares);

    event EtherReleased(address indexed beneficiary, uint256 amount);
    event ERC20Released(address indexed beneficiary, address indexed token, uint256 amount);

    event EtherRevoked(address indexed beneficiary, uint256 amount);
    event ERC20Revoked(address indexed beneficiary, address indexed token, uint256 amount);

    address public constant ETH = address(0);

    EnumerableSet.AddressSet private _beneficiaries;

    uint64 private _cliff;
    uint64 private _start;
    uint64 private _duration;

    bool private _revocable;

    uint256 private _totalShares;

    struct VestingData {
        uint256 shares;
        mapping(address asset => AssetInfo) assetsInfo;
    }

    struct AssetInfo {
        bool isRevoked;
        uint256 releasedAmount;
    }

    mapping(address beneficiary => VestingData) private _vestingData;
    mapping(address asset => uint256) private _totalReleased;

    function __VestingWallet_init(
        address[] memory beneficiaries_,
        uint256[] memory shares_,
        uint64 startTimestamp_,
        uint64 cliffSeconds_,
        uint64 durationSeconds_,
        bool revocable_
    ) internal onlyInitializing {
        require(
            beneficiaries_.length == shares_.length,
            "Vesting: beneficiaries and shares length mismatch"
        );
        require(beneficiaries_.length > 0, "Vesting: no beneficiaries");
        require(cliffSeconds_ <= durationSeconds_, "Vesting: cliff is longer than duration");
        require(
            startTimestamp_ + durationSeconds_ > block.timestamp,
            "Vesting: final time is before current time"
        );

        for (uint256 i = 0; i < beneficiaries_.length; i++) {
            _addBeneficiary(beneficiaries_[i], shares_[i]);
        }

        _start = startTimestamp_;
        _duration = durationSeconds_;
        _cliff = startTimestamp_ + cliffSeconds_;
        _revocable = revocable_;
    }

    receive() external payable virtual {}

    function releasable(address account_) public view virtual returns (uint256) {
        return vestedAmount(account_, uint64(block.timestamp)) - released(account_);
    }

    function releasable(address account_, address token_) public view virtual returns (uint256) {
        return
            vestedAmount(account_, token_, uint64(block.timestamp)) - released(account_, token_);
    }

    function vestedAmount(
        address account_,
        uint64 timestamp_
    ) public view virtual returns (uint256) {
        return _vestingSchedule(account_, beneficiaryAllocation(account_), timestamp_);
    }

    function vestedAmount(
        address account_,
        address token_,
        uint64 timestamp_
    ) public view virtual returns (uint256) {
        return
            _vestingSchedule(
                account_,
                token_,
                beneficiaryAllocation(account_, token_),
                timestamp_
            );
    }

    function beneficiaryAllocation(address account_) public view virtual returns (uint256) {
        return (totalAllocation() * shares(account_)) / totalShares();
    }

    function beneficiaryAllocation(
        address account_,
        address token_
    ) public view virtual returns (uint256) {
        return (totalAllocation(token_) * shares(account_)) / totalShares();
    }

    function totalAllocation() public view virtual returns (uint256) {
        return address(this).balance + totalReleased();
    }

    function totalAllocation(address token_) public view virtual returns (uint256) {
        return IERC20(token_).balanceOf(address(this)) + totalReleased(token_);
    }

    function totalReleased() public view virtual returns (uint256) {
        return _totalReleased[ETH];
    }

    function totalReleased(address token_) public view virtual returns (uint256) {
        return _totalReleased[token_];
    }

    function shares(address account_) public view virtual returns (uint256) {
        return _vestingData[account_].shares;
    }

    function totalShares() public view virtual returns (uint256) {
        return _totalShares;
    }

    function released(address account_) public view virtual returns (uint256) {
        return _vestingData[account_].assetsInfo[ETH].releasedAmount;
    }

    function released(address account_, address token_) public view virtual returns (uint256) {
        return _vestingData[account_].assetsInfo[token_].releasedAmount;
    }

    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    function end() public view virtual returns (uint256) {
        return start() + duration();
    }

    function isBeneficiary(address account_) public view virtual returns (bool) {
        return _beneficiaries.contains(account_);
    }

    function revocable() public view virtual returns (bool) {
        return _revocable;
    }

    function revoked(address account_) public view virtual returns (bool) {
        return _vestingData[account_].assetsInfo[ETH].isRevoked;
    }

    function revoked(address account_, address token_) public view virtual returns (bool) {
        return _vestingData[account_].assetsInfo[token_].isRevoked;
    }

    function vestingData(
        address account_
    ) public view virtual returns (uint256 _shares, AssetInfo memory _assetInfo) {
        VestingData storage _accountVesting = _vestingData[account_];

        _shares = _accountVesting.shares;
        _assetInfo = _accountVesting.assetsInfo[ETH];
    }

    function vestingData(
        address account_,
        address token_
    ) public view virtual returns (uint256 _shares, AssetInfo memory _assetInfo) {
        VestingData storage _accountVesting = _vestingData[account_];

        _shares = _accountVesting.shares;
        _assetInfo = _accountVesting.assetsInfo[token_];
    }

    function _vestingSchedule(
        address account_,
        uint256 totalAllocation_,
        uint64 timestamp_
    ) internal view virtual returns (uint256) {
        return _vestingSchedule(account_, ETH, totalAllocation_, timestamp_);
    }

    function _vestingSchedule(
        address account_,
        address token_,
        uint256 totalAllocation_,
        uint64 timestamp_
    ) internal view virtual returns (uint256) {
        if (timestamp_ < cliff()) {
            return 0;
        } else if (
            timestamp_ >= end() || token_ == ETH ? revoked(account_) : revoked(account_, token_)
        ) {
            return totalAllocation_;
        } else {
            return (totalAllocation_ * (timestamp_ - start())) / duration();
        }
    }

    function _release(address account_) internal virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");

        VestingData storage _accountVesting = _vestingData[account_];

        require(_accountVesting.shares > 0, "Vesting: account has no shares");

        uint256 _amount = releasable(account_);

        _accountVesting.assetsInfo[ETH].releasedAmount += _amount;
        _totalReleased[ETH] += _amount;

        Address.sendValue(payable(account_), _amount);

        emit EtherReleased(account_, _amount);
    }

    function _release(address account_, address token_) internal virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");

        VestingData storage _accountVesting = _vestingData[account_];

        require(_accountVesting.shares > 0, "Vesting: account has no shares");

        uint256 _amount = releasable(token_);

        _accountVesting.assetsInfo[token_].releasedAmount += _amount;
        _totalReleased[token_] += _amount;

        SafeERC20.safeTransfer(IERC20(token_), account_, _amount);

        emit ERC20Released(account_, token_, _amount);
    }

    function _revoke(address account_) internal virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");
        require(revocable(), "Vesting: cannot revoke");

        VestingData storage _accountVesting = _vestingData[account_];

        require(_accountVesting.shares > 0, "Vesting: account has no shares");

        AssetInfo storage _accountAssetInfo = _accountVesting.assetsInfo[ETH];

        require(!_accountAssetInfo.isRevoked, "Vesting: already revoked");

        uint256 _amount = beneficiaryAllocation(account_) - releasable(account_);

        _accountAssetInfo.isRevoked = true;

        Address.sendValue(payable(account_), _amount);

        emit EtherRevoked(account_, _amount);
    }

    function _revoke(address account_, address token_) internal virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");
        require(revocable(), "Vesting: cannot revoke");

        VestingData storage _accountVesting = _vestingData[account_];

        require(_accountVesting.shares > 0, "Vesting: account has no shares");

        AssetInfo storage _accountAssetInfo = _accountVesting.assetsInfo[token_];

        require(!_accountAssetInfo.isRevoked, "Vesting: already revoked");

        uint256 _amount = beneficiaryAllocation(account_, token_) - releasable(account_, token_);

        _accountAssetInfo.isRevoked = true;

        SafeERC20.safeTransfer(IERC20(token_), account_, _amount);

        emit ERC20Revoked(account_, token_, _amount);
    }

    function _addBeneficiary(address account_, uint256 shares_) private {
        VestingData storage _accountVesting = _vestingData[account_];

        require(account_ != ETH, "Vesting: account is the zero address");
        require(shares_ > 0, "Shares: shares are 0");
        require(_accountVesting.shares == 0, "Shares: account already has shares");

        _beneficiaries.add(account_);
        _accountVesting.shares = shares_;
        _totalShares += shares_;

        emit BeneficiaryAdded(account_, shares_);
    }
}
