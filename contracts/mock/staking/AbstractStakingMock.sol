// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AbstractStaking} from "../../staking/AbstractStaking.sol";

contract AbstractStakingMock is AbstractStaking {
    function __AbstractStakingMock_init(
        address sharesToken_,
        address rewardsToken_,
        uint256 rate_,
        uint256 stakingStartTime_
    ) external initializer {
        __AbstractStaking_init(sharesToken_, rewardsToken_, rate_, stakingStartTime_);
    }

    function mockInit(
        address sharesToken_,
        address rewardsToken_,
        uint256 rate_,
        uint256 stakingStartTime_
    ) external {
        __AbstractStaking_init(sharesToken_, rewardsToken_, rate_, stakingStartTime_);
    }

    function setStakingStartTime(uint256 stakingStartTime_) external {
        _setStakingStartTime(stakingStartTime_);
    }

    function userShares(address user_) external view returns (uint256) {
        return userDistribution(user_).shares;
    }

    function userOwedValue(address user_) external view returns (uint256) {
        return userDistribution(user_).owedValue;
    }
}
