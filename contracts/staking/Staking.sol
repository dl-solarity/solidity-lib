// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Staking {
    uint public rewardRate; // R
    uint public rewardPerToken; // r
    uint public totalSupply;

    mapping(address => uint) public stakedAmounts;
    mapping(address => uint) public rewardsPerTokenPaid;
    mapping(address => uint) public rewardsPerToken;

    uint public updatedAt;

    modifier updateReward(address _user) {
        _updateRewardPerToken(_user);

        _;
    }

    function _updateRewardPerToken(address _user) internal {
        rewardPerToken = calculateRewardPerToken();
        updatedAt = block.timestamp;

        // 1st -> rptPaid = 0
        //        rpt = r1
        // 2nd -> rptPaid = r1
        //        rpt = r2

        rewardsPerTokenPaid[_user] = rewardsPerToken[_user];
        rewardsPerToken[_user] = rewardPerToken;
    }

    function calculateRewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerToken;
        }

        return rewardPerToken + (rewardRate / totalSupply) * (block.timestamp - updatedAt);
    }

    function rewardEarned(address _user) public view returns (uint) {
        return stakedAmounts[_user] * (rewardsPerToken[_user] - rewardsPerTokenPaid[_user]);
    }

    function stake(uint amount) external updateReward(msg.sender) {}

    function withdraw(uint amount) external updateReward(msg.sender) {}
}
