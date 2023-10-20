// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VestingWallet is Ownable {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    event EtherRevoked(uint256 amount);
    event ERC20Revoked(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address token => uint256) private _erc20Released;

    bool private _revoked;
    mapping(address token => bool) private _erc20Revoked;

    uint64 private immutable _cliff;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    bool private immutable _revocable;

    constructor(
        address beneficiary_,
        uint64 startTimestamp_,
        uint64 cliffSeconds_,
        uint64 durationSeconds_,
        bool revocable_
    ) payable {
        require(cliffSeconds_ <= durationSeconds_, "Vesting: cliff is longer than duration");
        require(
            startTimestamp_ + durationSeconds_ > block.timestamp,
            "Vesting: final time is before current time"
        );

        _start = startTimestamp_;
        _duration = durationSeconds_;
        _cliff = startTimestamp_ + cliffSeconds_;
        _revocable = revocable_;

        transferOwnership(beneficiary_);
    }

    receive() external payable virtual {}

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

    function released() public view virtual returns (uint256) {
        return _released;
    }

    function released(address token_) public view virtual returns (uint256) {
        return _erc20Released[token_];
    }

    function revoked() public view virtual returns (bool) {
        return _revoked;
    }

    function revoked(address token_) public view virtual returns (bool) {
        return _erc20Revoked[token_];
    }

    function totalAllocation() public view virtual returns (uint256) {
        return address(this).balance + released();
    }

    function totalAllocation(address token_) public view virtual returns (uint256) {
        return IERC20(token_).balanceOf(address(this)) + released(token_);
    }

    // get the emount of eth that can be released at the current time
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    // get the emount of erc20 that can be released at the current time
    function releasable(address token_) public view virtual returns (uint256) {
        return vestedAmount(token_, uint64(block.timestamp)) - released(token_);
    }

    function release() public virtual {
        uint256 amount = releasable();

        _released += amount;

        Address.sendValue(payable(owner()), amount);

        emit EtherReleased(amount);
    }

    function release(address token_) public virtual {
        uint256 _amount = releasable(token_);

        _erc20Released[token_] += _amount;

        SafeERC20.safeTransfer(IERC20(token_), owner(), _amount);

        emit ERC20Released(token_, _amount);
    }

    function revoke() public virtual {
        require(revocable(), "Vesting: cannot revoke");
        require(!_revoked, "Vesting: already revoked");

        uint256 _amount = address(this).balance - releasable();

        _revoked = true;

        Address.sendValue(payable(owner()), _amount);

        emit EtherRevoked(_amount);
    }

    function revoke(address token_) public virtual {
        require(revocable(), "Vesting: cannot revoke");
        require(!_erc20Revoked[token_], "Vesting: already revoked");

        uint256 _amount = IERC20(token_).balanceOf(address(this)) - releasable(token_);

        _erc20Revoked[token_] = true;

        SafeERC20.safeTransfer(IERC20(token_), owner(), _amount);

        emit ERC20Revoked(token_, _amount);
    }

    function vestedAmount(uint64 timestamp_) public view virtual returns (uint256) {
        return _vestingSchedule(totalAllocation(), timestamp_);
    }

    function vestedAmount(
        address token_,
        uint64 timestamp_
    ) public view virtual returns (uint256) {
        return _vestingSchedule(totalAllocation(token_), timestamp_);
    }

    function _vestingSchedule(
        uint256 totalAllocation_,
        uint64 timestamp_
    ) internal view virtual returns (uint256) {
        return _vestingSchedule(address(0), totalAllocation_, timestamp_);
    }

    function _vestingSchedule(
        address token_,
        uint256 totalAllocation_,
        uint64 timestamp_
    ) internal view virtual returns (uint256) {
        if (timestamp_ < cliff()) {
            return 0;
        } else if (timestamp_ >= end() || revoked() || revoked(token_)) {
            return totalAllocation_;
        } else {
            return (totalAllocation_ * (timestamp_ - start())) / duration();
        }
    }
}
