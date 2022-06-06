// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompoundRateKeeperV2.sol";

interface IStaking is ICompoundRateKeeperV2 {
    event Staked(address staker, uint256 amount);
    event Withdrawn(address staker, uint256 amount);

    struct Stake {
        uint256 amount;
        uint256 normalizedAmount;
        uint64 lastUpdate;
    }

    /**
     * @notice Stake tokens to contract.
     * @param _amount Stake amount, wei.
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Withdraw tokens from stake.
     * @param _amount Tokens amount to withdraw, wei.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Return amount of tokens + percents at this moment.
     * @param _address Staker address.
     */
    function getAvailableAmount(address _address) external view returns (uint256);

    /**
     * @notice Return amount of tokens + percents at given timestamp.
     * @param _address Staker address.
     * @param _timestamp Given timestamp, seconds.
     */
    function getPotentialAmount(address _address, uint64 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @notice Transfer tokens to contract as reward.
     * @param _amount Token amount, wei.
     */
    function supplyRewardPool(uint256 _amount) external;

    /**
     * @notice Return coefficient in decimals. If coefficient more or equal to 1, all holders will
     * be able to receive awards at this moment.
     */
    function monitorSecurityMargin() external view returns (uint256);

    /**
     * @notice Withdrawal of excess tokens.
     * @param _token Token address.
     * @param _amount Token amount, wei.
     * @param _to Recipient address.
     */
    function withdrawERC20(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external;
}
