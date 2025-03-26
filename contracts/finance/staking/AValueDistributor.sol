// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PRECISION} from "../../utils/Globals.sol";

/**
 * @notice The Staking module
 *
 * Contract module for distributing value among users based on their shares.
 *
 * The algorithm ensures that the distribution is proportional to the shares
 * held by each user and takes into account changes in the cumulative sum over time.
 *
 * This contract can be used as a base contract for implementing various distribution mechanisms,
 * such as token staking, profit sharing, or dividend distribution.
 *
 * It includes hooks for performing additional logic
 * when shares are added or removed, or when value is distributed.
 */
abstract contract AValueDistributor {
    struct UserDistribution {
        uint256 shares;
        uint256 cumulativeSum;
        uint256 owedValue;
    }

    struct AValueDistributorStorage {
        uint256 totalShares;
        uint256 cumulativeSum;
        uint256 updatedAt;
        mapping(address user => UserDistribution distribution) userDistributions;
    }

    // bytes32(uint256(keccak256("solarity.contract.AValueDistributor")) - 1)
    bytes32 private constant A_VALUE_DISTRIBUTOR_STORAGE =
        0x3787c5369be7468820c1967d258d594c4479f12333b91d3edff0bcbb43e7bf8f;

    event SharesAdded(address user, uint256 amount);
    event SharesRemoved(address user, uint256 amount);
    event ValueDistributed(address user, uint256 amount);

    error AmountIsZero();
    error InsufficientOwedValue(address account, uint256 balance, uint256 needed);
    error InsufficientSharesAmount(address account, uint256 balance, uint256 needed);
    error UserIsZeroAddress();

    /**
     * @notice Returns the total number of shares.
     * @return The total number of shares.
     */
    function totalShares() public view returns (uint256) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        return $.totalShares;
    }

    /**
     * @notice Returns the cumulative sum of value that has been distributed.
     * @return The cumulative sum of value that has been distributed.
     */
    function cumulativeSum() public view returns (uint256) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        return $.cumulativeSum;
    }

    /**
     * @notice Returns the timestamp of the last update.
     * @return The timestamp of the last update.
     */
    function updatedAt() public view returns (uint256) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        return $.updatedAt;
    }

    /**
     * @notice Returns the distribution details for a specific user.
     * @param user_ The address of the user.
     * @return The distribution details including user's shares, cumulative sum and value owed.
     */
    function userDistribution(address user_) public view returns (UserDistribution memory) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        return $.userDistributions[user_];
    }

    /**
     * @notice Gets the amount of value owed to a specific user.
     * @param user_ The address of the user.
     * @return The total owed value to the user.
     */
    function getOwedValue(address user_) public view returns (uint256) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        UserDistribution storage userDist = $.userDistributions[user_];

        return
            (userDist.shares *
                (_getFutureCumulativeSum(block.timestamp) - userDist.cumulativeSum)) /
            PRECISION +
            userDist.owedValue;
    }

    /**
     * @notice Adds shares to a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares to add.
     */
    function _addShares(address user_, uint256 amount_) internal virtual {
        if (user_ == address(0)) revert UserIsZeroAddress();
        if (amount_ == 0) revert AmountIsZero();

        _update(user_);

        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        $.totalShares += amount_;
        $.userDistributions[user_].shares += amount_;

        emit SharesAdded(user_, amount_);

        _afterAddShares(user_, amount_);
    }

    /**
     * @notice Removes shares from a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares to remove.
     */
    function _removeShares(address user_, uint256 amount_) internal virtual {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        UserDistribution storage _userDist = $.userDistributions[user_];

        if (amount_ == 0) revert AmountIsZero();
        if (amount_ > _userDist.shares)
            revert InsufficientSharesAmount(user_, _userDist.shares, amount_);

        _update(user_);

        $.totalShares -= amount_;
        _userDist.shares -= amount_;

        emit SharesRemoved(user_, amount_);

        _afterRemoveShares(user_, amount_);
    }

    /**
     * @notice Distributes value to a specific user.
     * @param user_ The address of the user.
     * @param amount_ The amount of value to distribute.
     */
    function _distributeValue(address user_, uint256 amount_) internal virtual {
        _update(user_);

        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        UserDistribution storage _userDist = $.userDistributions[user_];

        if (amount_ == 0) revert AmountIsZero();
        if (amount_ > _userDist.owedValue)
            revert InsufficientOwedValue(user_, _userDist.owedValue, amount_);

        _userDist.owedValue -= amount_;

        emit ValueDistributed(user_, amount_);

        _afterDistributeValue(user_, amount_);
    }

    /**
     * @notice Distributes all the available value to a specific user.
     * @param user_ The address of the user.
     * @return The amount of value distributed.
     */
    function _distributeAllValue(address user_) internal virtual returns (uint256) {
        _update(user_);

        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        UserDistribution storage _userDist = $.userDistributions[user_];

        uint256 amount_ = _userDist.owedValue;

        if (amount_ == 0) revert AmountIsZero();

        delete _userDist.owedValue;

        emit ValueDistributed(user_, amount_);

        _afterDistributeValue(user_, amount_);

        return amount_;
    }

    /**
     * @notice Hook function that is called after shares have been added to a user's distribution.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of shares added.
     */
    function _afterAddShares(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Hook function that is called after shares have been removed from a user's distribution.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of shares removed.
     */
    function _afterRemoveShares(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Hook function that is called after value has been distributed to a user.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of value distributed.
     */
    function _afterDistributeValue(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Updates the cumulative sum of tokens that have been distributed.
     *
     * This function should be called whenever user shares are modified or value distribution occurs.
     *
     * @param user_ The address of the user.
     */
    function _update(address user_) internal {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        $.cumulativeSum = _getFutureCumulativeSum(block.timestamp);
        $.updatedAt = block.timestamp;

        if (user_ != address(0)) {
            UserDistribution storage _userDist = $.userDistributions[user_];

            _userDist.owedValue +=
                (_userDist.shares * ($.cumulativeSum - _userDist.cumulativeSum)) /
                PRECISION;
            _userDist.cumulativeSum = $.cumulativeSum;
        }
    }

    /**
     * @notice Gets the value to be distributed for a given time period.
     *
     * Note: It will usually be required to override this function to provide custom distribution mechanics.
     *
     * @param timeUpTo_ The end timestamp of the period.
     * @param timeLastUpdate_ The start timestamp of the period.
     * @return The value to be distributed for the period.
     */
    function _getValueToDistribute(
        uint256 timeUpTo_,
        uint256 timeLastUpdate_
    ) internal view virtual returns (uint256);

    /**
     * @notice Gets the expected cumulative sum of value per token staked distributed at a given timestamp.
     * @param timeUpTo_ The timestamp up to which to calculate the value distribution.
     * @return The future cumulative sum of value per token staked that has been distributed.
     */
    function _getFutureCumulativeSum(uint256 timeUpTo_) internal view returns (uint256) {
        AValueDistributorStorage storage $ = _getAValueDistributorStorage();

        if ($.totalShares == 0) {
            return $.cumulativeSum;
        }

        uint256 value_ = _getValueToDistribute(timeUpTo_, $.updatedAt);

        return $.cumulativeSum + (value_ * PRECISION) / $.totalShares;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getAValueDistributorStorage()
        private
        pure
        returns (AValueDistributorStorage storage $)
    {
        assembly {
            $.slot := A_VALUE_DISTRIBUTOR_STORAGE
        }
    }
}
