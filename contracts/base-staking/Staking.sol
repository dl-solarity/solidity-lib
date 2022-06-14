// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./CompoundRateKeeperV2.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking, CompoundRateKeeperV2 {
    using SafeERC20 for IERC20;
    using Math for uint256;

    mapping(address => Stake) public addressToStake;

    IERC20 public token;

    /// @notice Stake start timestamp.
    uint64 public startTimestamp;
    /// @notice Stake end timestamp.
    uint64 public endTimestamp;
    /// @notice Period when address can't withdraw after stake.
    uint64 public lockPeriod;

    uint256 public aggregatedAmount;
    uint256 public aggregatedNormalizedAmount;

    constructor(
        IERC20 _token,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint64 _lockPeriod,
        uint256 _annualPercent
    ) CompoundRateKeeperV2(_annualPercent) {
        require(
            block.timestamp < _startTimestamp && _startTimestamp < _endTimestamp,
            "Staking: incorrect timestamps"
        );

        token = _token;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lockPeriod = _lockPeriod;
    }

    function stake(uint256 _amount) external override {
        require(_amount > 0, "Staking: amount can't be a zero");
        require(block.timestamp >= startTimestamp, "Staking: staking is not started");
        require(block.timestamp <= endTimestamp, "Staking: staking is ended");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;

        uint256 _newAmount = _amount + __getAvailableAmount(_normalizedAmount, _compoundRate);
        uint256 _newNormalizedAmount = __getNormalizedAmount(_newAmount, _compoundRate);

        aggregatedAmount += _amount;
        aggregatedNormalizedAmount =
            aggregatedNormalizedAmount +
            _newNormalizedAmount -
            _normalizedAmount;

        addressToStake[msg.sender].amount += _amount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;
        addressToStake[msg.sender].lastUpdate = uint64(block.timestamp);

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external override {
        require(_amount > 0, "Staking: amount can't be a zero");
        require(
            block.timestamp > addressToStake[msg.sender].lastUpdate + lockPeriod,
            "Staking: tokens locked"
        );

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _availableAmount = __getAvailableAmount(_normalizedAmount, _compoundRate);
        require(_availableAmount > 0, "Staking: nothing to withdraw");

        _amount = _amount.min(_availableAmount);

        uint256 _newAmount = _availableAmount - _amount;
        uint256 _newNormalizedAmount = __getNormalizedAmount(_newAmount, _compoundRate);

        if (_newAmount < addressToStake[msg.sender].amount) {
            aggregatedAmount = aggregatedAmount + _newAmount - addressToStake[msg.sender].amount;
            addressToStake[msg.sender].amount = _newAmount;
        }

        aggregatedNormalizedAmount =
            aggregatedNormalizedAmount +
            _newNormalizedAmount -
            _normalizedAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;

        token.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /// @dev Return amount of tokens + percents at this moment.
    function getAvailableAmount(address _address) external view override returns (uint256) {
        return __getAvailableAmount(addressToStake[_address].normalizedAmount, getCompoundRate());
    }

    /// @dev Return amount of tokens + percents at given timestamp.
    function getPotentialAmount(address _address, uint64 _timestamp)
        external
        view
        override
        returns (uint256)
    {
        return
            (addressToStake[_address].normalizedAmount * getPotentialCompoundRate(_timestamp)) /
            _getDecimals();
    }

    function supplyRewardPool(uint256 _amount) external override {
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function monitorSecurityMargin() external view override returns (uint256) {
        uint256 _toWithdraw = __getAvailableAmount(aggregatedNormalizedAmount, getCompoundRate());

        if (_toWithdraw == 0) return _getDecimals();
        return (token.balanceOf(address(this)) * _getDecimals()) / _toWithdraw;
    }

    function withdrawERC20(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        if (address(token) == address(_token)) {
            uint256 _availableAmount = token.balanceOf(address(this)) -
                __getAvailableAmount(aggregatedNormalizedAmount, getCompoundRate());
            _amount = _amount.min(_availableAmount);
        }

        return _token.safeTransfer(_to, _amount);
    }

    function __getAvailableAmount(uint256 _normalizedAmount, uint256 _compoundRate)
        private
        pure
        returns (uint256)
    {
        return (_normalizedAmount * _compoundRate) / _getDecimals();
    }

    function __getNormalizedAmount(uint256 _amount, uint256 _compoundRate)
        private
        pure
        returns (uint256)
    {
        return (_amount * _getDecimals()) / _compoundRate;
    }
}
