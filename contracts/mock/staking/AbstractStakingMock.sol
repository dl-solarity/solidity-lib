// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AbstractStaking} from "../../staking/AbstractStaking.sol";

contract AbstractStakingMock is AbstractStaking, Multicall {
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

    function setRate(uint256 newRate_) external {
        _setRate(newRate_);
    }

    function userShares(address user_) external view returns (uint256) {
        return userDistribution(user_).shares;
    }

    function userOwedValue(address user_) external view returns (uint256) {
        return userDistribution(user_).owedValue;
    }
}

contract StakersFactory is Multicall {
    Staker[] public stakers;

    function createStaker() public {
        Staker staker_ = new Staker();
        stakers.push(staker_);
    }

    function stake(
        address stakingContract_,
        address staker_,
        address token_,
        uint256 amount_
    ) external {
        Staker(staker_).stake(stakingContract_, token_, amount_);
    }

    function unstake(address stakingContract_, address staker_, uint256 amount_) external {
        Staker(staker_).unstake(stakingContract_, amount_);
    }
}

contract Staker {
    function stake(address stakingContract_, address token_, uint256 amount_) external {
        IERC20(token_).approve(stakingContract_, amount_);
        AbstractStakingMock(stakingContract_).stake(amount_);
    }

    function unstake(address stakingContract_, uint256 amount_) external {
        AbstractStakingMock(stakingContract_).unstake(amount_);
    }
}
