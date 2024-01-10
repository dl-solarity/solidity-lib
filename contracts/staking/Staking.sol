// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ValueDistributor} from "./ValueDistributor.sol";

contract Staking is ValueDistributor, Initializable {
    address private _sharesToken;
    address private _rewardsToken;

    /**
     * @dev The rate of rewards distribution per second.
     *
     * It determines the rate at which rewards are earned and distributed
     * to stakers based on their shares.
     *
     * Note: Ensure that the `_rate` value is set correctly to match
     * the decimal precision of the `_rewardsToken` to ensure accurate rewards distribution.
     */
    uint256 private _rate;

    uint256 private _stakingStartTime;

    /**
     * @dev Throws if the staking has not started yet.
     */
    modifier stakingStarted() {
        _checkStakingStarted();

        _;
    }

    /**
     * @notice Initializes the contract setting the values provided as shares token, rewards token, reward rate and staking start time.
     * @param sharesToken_ The address of the shares token.
     * @param rewardsToken_ The address of the rewards token.
     * @param rate_ The reward rate.
     * @param stakingStartTime_ The staking start time
     */
    function __Staking_init(
        address sharesToken_,
        address rewardsToken_,
        uint256 rate_,
        uint256 stakingStartTime_
    ) internal onlyInitializing {
        require(sharesToken_ != address(0), "Staking: zero address cannot be the Shares Token");
        require(rewardsToken_ != address(0), "Staking: zero address cannot be the Rewards Token");
        require(rate_ > 0, "Staking: rate has to be more than 0");

        _sharesToken = sharesToken_;
        _rewardsToken = rewardsToken_;
        _setRate(rate_);
        _setStakingStartTime(stakingStartTime_);
    }

    /**
     * @notice Stakes the specified amount of tokens.
     * @param amount_ The amount of tokens to stake.
     */
    function stake(uint256 amount_) public stakingStarted {
        _addShares(msg.sender, amount_);
    }

    /**
     * @notice Withdraws all the staked tokens.
     *
     * Note: All the rewards are claimed after the shares were removed.
     */
    function withdraw() public stakingStarted {
        unstake(userDistribution(msg.sender).shares);

        claim(getOwedValue(msg.sender));
    }

    /**
     * @notice Unstakes the specified amount of tokens.
     * @param amount_ The amount of tokens to unstake.
     */
    function unstake(uint256 amount_) public stakingStarted {
        _removeShares(msg.sender, amount_);
    }

    /**
     * @notice Claims the specified amount of rewards.
     * @param amount_ The amount of rewards to claim.
     */
    function claim(uint256 amount_) public stakingStarted {
        uint256 owed = userDistribution(msg.sender).owedValue;
        require(amount_ <= owed, "Staking: insufficient amount");

        _distributeValue(msg.sender, amount_);
    }

    /**
     * @notice Returns the shares token.
     * @return The address of the shares token contract.
     */
    function sharesToken() public view returns (address) {
        return _sharesToken;
    }

    /**
     * @notice Returns the rewards token.
     * @return The address of the rewards token contract.
     */
    function rewardsToken() public view returns (address) {
        return _rewardsToken;
    }

    /**
     * @notice Returns the staking start time.
     * @return The timestamp when staking started.
     */
    function stakingStartTime() public view returns (uint256) {
        return _stakingStartTime;
    }

    /**
     * @notice Returns the rate of rewards distribution.
     * @return The rate of rewards distribution per second.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @notice Sets the staking start time.
     * @param stakingStartTime_ The timestamp when staking will start.
     */
    function _setStakingStartTime(uint256 stakingStartTime_) internal {
        _stakingStartTime = stakingStartTime_;
    }

    /**
     * @notice Sets the rate of rewards distribution per second.
     * @param newRate_ The new rate of rewards distribution.
     */
    function _setRate(uint256 newRate_) internal {
        _update(address(0));

        _rate = newRate_;
    }

    /**
     * @notice Hook function that is called after shares have been added to a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares added.
     */
    function _afterAddShares(address user_, uint256 amount_) internal virtual override {
        SafeERC20.safeTransferFrom(IERC20(_sharesToken), user_, address(this), amount_);
    }

    /**
     * @notice Hook function that is called after shares have been removed from a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares removed.
     */
    function _afterRemoveShares(address user_, uint256 amount_) internal virtual override {
        SafeERC20.safeTransfer(IERC20(_sharesToken), user_, amount_);
    }

    /**
     * @notice Hook function that is called after value has been distributed to a user.
     * @param user_ The address of the user.
     * @param amount_ The amount of value distributed.
     */
    function _afterDistributeValue(address user_, uint256 amount_) internal virtual override {
        SafeERC20.safeTransfer(IERC20(_rewardsToken), user_, amount_);
    }

    /**
     * @dev Throws if the staking has not started yet.
     */
    function _checkStakingStarted() internal view {
        require(block.timestamp >= _stakingStartTime, "Staking: staking has not started yet");
    }

    /**
     * @notice Gets the value to be distributed for a given time period.
     * @param timeUpTo The end timestamp of the period.
     * @param timeLastUpdate The start timestamp of the period.
     * @return The value to be distributed for the period.
     */
    function _getValueToDistribute(
        uint256 timeUpTo,
        uint256 timeLastUpdate
    ) internal view virtual override returns (uint256) {
        return _rate * (timeUpTo - timeLastUpdate);
    }
}
