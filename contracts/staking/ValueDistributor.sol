// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PRECISION, DECIMAL} from "../utils/Globals.sol";

abstract contract ValueDistributor {
    struct UserDistribution {
        uint256 shares;
        uint256 cumulativeSum;
        uint256 owedValue;
    }

    uint256 public totalShares;
    uint256 public cumulativeSum;
    uint256 public updatedAt;

    mapping(address => UserDistribution) public userDistributions;

    function getOwedValue(address user_) public view returns (uint256) {
        UserDistribution storage userDist = userDistributions[user_];

        return
            (userDist.shares *
                (_getFutureCumulativeSum(block.timestamp) - userDist.cumulativeSum)) /
            PRECISION +
            userDist.owedValue;
    }

    function _addShares(address user_, uint256 amount_) internal virtual {
        _update(user_);

        totalShares += amount_;
        userDistributions[user_].shares += amount_;

        _afterAddShares(user_, amount_);
    }

    function _removeShares(address user_, uint256 amount_) internal virtual {
        _update(user_);

        // FIXME add requires
        totalShares -= amount_;
        userDistributions[user_].shares -= amount_;

        _afterRemoveShares(user_, amount_);
    }

    function _afterAddShares(address user_, uint256 amount_) internal virtual {}

    function _afterRemoveShares(address user_, uint256 amount_) internal virtual {}

    function _getValueToDistribute(
        uint256 timeUpTo,
        uint256 timeLastUpdate
    ) internal view virtual returns (uint256) {
        return DECIMAL * (timeUpTo - timeLastUpdate); // 1 token with 18 decimals per second
    }

    function _update(address user_) internal {
        if (updatedAt == 0) {
            updatedAt = block.timestamp;
            return;
        }

        cumulativeSum = _getFutureCumulativeSum(block.timestamp);
        updatedAt = block.timestamp;

        if (user_ != address(0)) {
            UserDistribution storage userDist = userDistributions[user_];

            userDist.owedValue +=
                (userDist.shares * (cumulativeSum - userDist.cumulativeSum)) /
                PRECISION;
            userDist.cumulativeSum = cumulativeSum;
        }
    }

    function _getFutureCumulativeSum(uint256 timeUpTo) internal view returns (uint256) {
        uint256 value_ = _getValueToDistribute(timeUpTo, updatedAt);

        return cumulativeSum + (value_ * PRECISION) / totalShares;
    }
}
