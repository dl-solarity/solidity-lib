// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "../libs/arrays/SetHelper.sol";

contract VestingWallet {
    using EnumerableSet for EnumerableSet.AddressSet;

    event BeneficiaryAdded(address account, uint256 shares);

    event EtherReleased(address indexed beneficiary, uint256 amount);
    event ERC20Released(address indexed beneficiary, address indexed token, uint256 amount);

    event EtherRevoked(address indexed beneficiary, uint256 amount);
    event ERC20Revoked(address indexed beneficiary, address indexed token, uint256 amount);

    EnumerableSet.AddressSet private _beneficiaries;

    uint64 private immutable _cliff;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    bool private immutable _revocable;

    uint256 private _totalShares;
    uint256 private _ethTotalReleased;

    mapping(address beneficiary => uint256) private _shares;

    mapping(address beneficiary => uint256) private _ethReleased;
    mapping(address token => uint256) private _erc20TotalReleased;
    mapping(address beneficiary => mapping(address token => uint256)) private _erc20Released;

    mapping(address beneficiary => bool) private _ethRevoked;
    mapping(address beneficiary => mapping(address token => bool)) private _erc20Revoked;

    constructor(
        address[] memory beneficiaries_,
        uint256[] memory shares_,
        uint64 startTimestamp_,
        uint64 cliffSeconds_,
        uint64 durationSeconds_,
        bool revocable_
    ) payable {
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

    function isBeneficiary(address account_) public view virtual returns (bool) {
        return _beneficiaries.contains(account_);
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    function end() public view virtual returns (uint256) {
        return start() + duration();
    }

    function revocable() public view virtual returns (bool) {
        return _revocable;
    }

    function released(address account_) public view virtual returns (uint256) {
        return _ethReleased[account_];
    }

    function released(address account_, address token_) public view virtual returns (uint256) {
        return _erc20Released[account_][token_];
    }

    function totalReleased() public view virtual returns (uint256) {
        return _ethTotalReleased;
    }

    function totalReleased(address token_) public view virtual returns (uint256) {
        return _erc20TotalReleased[token_];
    }

    function shares(address account_) public view virtual returns (uint256) {
        return _shares[account_];
    }

    function totalShares() public view virtual returns (uint256) {
        return _totalShares;
    }

    function revoked(address account_) public view virtual returns (bool) {
        return _ethRevoked[account_];
    }

    function revoked(address account_, address token_) public view virtual returns (bool) {
        return _erc20Revoked[account_][token_];
    }

    function totalAllocation() public view virtual returns (uint256) {
        return address(this).balance + totalReleased();
    }

    function totalAllocation(address token_) public view virtual returns (uint256) {
        return IERC20(token_).balanceOf(address(this)) + totalReleased(token_);
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

    function releasable(address account_) public view virtual returns (uint256) {
        return vestedAmount(account_, uint64(block.timestamp)) - released(account_);
    }

    function releasable(address account_, address token_) public view virtual returns (uint256) {
        return
            vestedAmount(account_, token_, uint64(block.timestamp)) - released(account_, token_);
    }

    function release(address account_) public virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");
        require(_shares[account_] > 0, "PaymentSplitter: account has no shares");

        uint256 _amount = releasable(account_);

        _ethTotalReleased += _amount;
        _ethReleased[account_] += _amount;

        Address.sendValue(payable(account_), _amount);

        emit EtherReleased(account_, _amount);
    }

    function release(address account_, address token_) public virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");

        uint256 _amount = releasable(token_);

        _erc20TotalReleased[token_] += _amount;
        _erc20Released[account_][token_] += _amount;

        SafeERC20.safeTransfer(IERC20(token_), account_, _amount);

        emit ERC20Released(account_, token_, _amount);
    }

    function revoke(address account_) public virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");

        require(revocable(), "Vesting: cannot revoke");
        require(!_ethRevoked[account_], "Vesting: already revoked");

        uint256 _amount = beneficiaryAllocation(account_) - releasable(account_);

        _ethRevoked[account_] = true;

        Address.sendValue(payable(account_), _amount);

        emit EtherRevoked(account_, _amount);
    }

    function revoke(address account_, address token_) public virtual {
        require(_beneficiaries.contains(account_), "Vesting: not a beneficiary");

        require(revocable(), "Vesting: cannot revoke");
        require(!_erc20Revoked[account_][token_], "Vesting: already revoked");

        uint256 _amount = beneficiaryAllocation(account_, token_) - releasable(account_, token_);

        _erc20Revoked[account_][token_] = true;

        SafeERC20.safeTransfer(IERC20(token_), account_, _amount);

        emit ERC20Revoked(account_, token_, _amount);
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

    function _vestingSchedule(
        address account_,
        uint256 totalAllocation_,
        uint64 timestamp_
    ) internal view virtual returns (uint256) {
        return _vestingSchedule(account_, address(0), totalAllocation_, timestamp_);
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
            timestamp_ >= end() || token_ == address(0)
                ? revoked(account_)
                : revoked(account_, token_)
        ) {
            return totalAllocation_;
        } else {
            return (totalAllocation_ * (timestamp_ - start())) / duration();
        }
    }

    function _addBeneficiary(address account_, uint256 shares_) private {
        require(account_ != address(0), "Vesting: account is the zero address");
        require(shares_ > 0, "Shares: shares are 0");
        require(_shares[account_] == 0, "Shares: account already has shares");

        _beneficiaries.add(account_);
        _shares[account_] = shares_;
        _totalShares += shares_;

        emit BeneficiaryAdded(account_, shares_);
    }
}
