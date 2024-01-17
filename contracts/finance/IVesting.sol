// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVesting {
    // structure of vesting object
    struct VestingData {
        bool isActive;
        address beneficiary;
        uint256 totalAmount;
        uint256 paidAmount;
        bool isRevocable;
        string scheduleType;
    }

    function getAvailableAmount() external view returns (uint256);

    function getReleasedAmount(uint256 vestingId_) external view returns (uint256);

    function getWithdrawableAmount(uint256 vestingId_) external view returns (uint256);

    function getVesting(uint256 vestingId_) external view returns (VestingData memory);

    function getVestings(address beneficiary) external view returns (VestingData[] memory);

    function getVestingIds(address beneficiary) external view returns (uint256[] memory);
}
