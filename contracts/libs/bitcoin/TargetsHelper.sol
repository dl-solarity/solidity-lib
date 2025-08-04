// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice A library providing helper functions for Bitcoin's difficulty target calculations.
 * This includes target adjustments, work calculations, and conversions between bits and targets
 */
library TargetsHelper {
    /**
     * @notice The ideal expected time for 2016 blocks to be mined, in seconds.
     * This is based on a 10-minute block interval
     */
    uint256 public constant EXPECTED_TARGET_BLOCKS_TIME = 1209600;
    /**
     * @notice The number of blocks after which the difficulty target is adjusted.
     * This is a fundamental constant in Bitcoin's difficulty adjustment algorithm
     */
    uint256 public constant DIFFICULTY_ADJUSTMENT_INTERVAL = 2016;

    /**
     * @notice The initial difficulty target for the Bitcoin blockchain.
     * This represents the highest possible difficulty (lowest target value)
     */
    bytes32 public constant INITIAL_TARGET =
        0x00000000ffff0000000000000000000000000000000000000000000000000000;

    /**
     * @notice A factor used for fixed-point arithmetic in target calculations.
     * This helps maintain precision when dealing with ratios
     */
    uint256 public constant TARGET_FIXED_POINT_FACTOR = 10 ** 18;
    /**
     * @notice The maximum factor by which the target can change in a single adjustment period.
     * This limits how much the difficulty can decrease
     */
    uint256 public constant MAX_TARGET_FACTOR = 4;

    /**
     * @notice The maximum ratio for target adjustment, calculated as `TARGET_FIXED_POINT_FACTOR * MAX_TARGET_FACTOR`.
     * Ensures the target doesn't increase too much
     */
    uint256 public constant MAX_TARGET_RATIO = TARGET_FIXED_POINT_FACTOR * MAX_TARGET_FACTOR;
    /**
     * @notice The minimum ratio for target adjustment, calculated as `TARGET_FIXED_POINT_FACTOR / MAX_TARGET_FACTOR`
     * Ensures the target doesn't decrease too much.
     */
    uint256 public constant MIN_TARGET_RATIO = TARGET_FIXED_POINT_FACTOR / MAX_TARGET_FACTOR;

    /**
     * @notice Checks if a given block height is a target adjustment block.
     * Adjustment occurs every `DIFFICULTY_ADJUSTMENT_INTERVAL` blocks
     * @param blockHeight_ The height of the block to check
     * @return True if it's an adjustment block, false otherwise
     */
    function isTargetAdjustmentBlock(uint256 blockHeight_) internal pure returns (bool) {
        return getEpochBlockNumber(blockHeight_) == 0 && blockHeight_ > 0;
    }

    /**
     * @notice Calculates the block number within the current difficulty adjustment epoch.
     * The epoch starts at block height `0` and resets every `DIFFICULTY_ADJUSTMENT_INTERVAL` blocks
     * @param blockHeight_ The height of the block
     * @return The block number within its current epoch
     */
    function getEpochBlockNumber(uint256 blockHeight_) internal pure returns (uint256) {
        return blockHeight_ % DIFFICULTY_ADJUSTMENT_INTERVAL;
    }

    /**
     * @notice Calculates and rounds the new difficulty target based on current target and actual passed time.
     * This function applies both the target adjustment and the rounding rules
     * @param currentTarget_ The current difficulty target
     * @param actualPassedTime_ The actual time taken to mine the last `DIFFICULTY_ADJUSTMENT_INTERVAL` blocks
     * @return The new, rounded difficulty target
     */
    function countNewRoundedTarget(
        bytes32 currentTarget_,
        uint256 actualPassedTime_
    ) internal pure returns (bytes32) {
        return _roundTarget(countNewTarget(currentTarget_, actualPassedTime_));
    }

    /**
     * @notice Calculates the new difficulty target without rounding.
     * It adjusts the target based on the difference between actual and expected block times, clamping the adjustment
     * @param currentTarget_ The current difficulty target
     * @param actualPassedTime_ The actual time taken to mine the last `DIFFICULTY_ADJUSTMENT_INTERVAL` blocks
     * @return The new difficulty target before rounding
     */
    function countNewTarget(
        bytes32 currentTarget_,
        uint256 actualPassedTime_
    ) internal pure returns (bytes32) {
        uint256 currentRatio = (actualPassedTime_ * TARGET_FIXED_POINT_FACTOR) /
            EXPECTED_TARGET_BLOCKS_TIME;

        currentRatio = Math.min(Math.max(currentRatio, MIN_TARGET_RATIO), MAX_TARGET_RATIO);

        bytes32 target_ = bytes32(
            Math.mulDiv(uint256(currentTarget_), currentRatio, TARGET_FIXED_POINT_FACTOR)
        );

        return target_ > INITIAL_TARGET ? INITIAL_TARGET : target_;
    }

    /**
     * @notice Calculates the cumulative work for an entire difficulty adjustment epoch.
     * This is the sum of block work for all blocks within an epoch
     * @param epochTarget_ The difficulty target for the epoch
     * @return The cumulative work for the epoch
     */
    function countEpochCumulativeWork(bytes32 epochTarget_) internal pure returns (uint256) {
        return countCumulativeWork(epochTarget_, DIFFICULTY_ADJUSTMENT_INTERVAL);
    }

    /**
     * @notice Calculates the total cumulative work for a specified number of blocks.
     * This is the product of the block work and the number of blocks
     * @param epochTarget_ The difficulty target for the blocks
     * @param blocksCount_ The number of blocks to count cumulative work for
     * @return The total cumulative work
     */
    function countCumulativeWork(
        bytes32 epochTarget_,
        uint256 blocksCount_
    ) internal pure returns (uint256) {
        return countBlockWork(epochTarget_) * blocksCount_;
    }

    /**
     * @notice Calculates the work required for a single block given its difficulty target.
     * This is a measure of the computational effort to find a block
     * @param target_ The difficulty target of the block
     * @return blockWork_ The work for the block
     */
    function countBlockWork(bytes32 target_) internal pure returns (uint256 blockWork_) {
        assembly {
            // Work is calculated as (2^256 - 1) / (target + 1)
            blockWork_ := div(not(blockWork_), add(target_, 0x1))
        }
    }

    /**
     * @notice Converts the compact "bits" representation of difficulty to the full 256-bit target
     * This uses inline assembly for efficient bit manipulation
     * @param bits_ The compact difficulty bits
     * @return target_ The full 256-bit target
     */
    function bitsToTarget(bytes4 bits_) internal pure returns (bytes32 target_) {
        assembly {
            let targetShift := mul(sub(0x20, byte(0, bits_)), 0x8)

            target_ := shr(targetShift, shl(0x8, bits_))
        }
    }

    /**
     * @notice Converts the full 256-bit target to the compact "bits" representation of difficulty
     * This uses inline assembly for efficient bit manipulation
     * @param target_ The full 256-bit target
     * @return bits_ The compact difficulty bits
     */
    function targetToBits(bytes32 target_) internal pure returns (bytes4 bits_) {
        assembly {
            let coefficientLength := 0x3
            let coefficientStartIndex := 0

            let bitsPtr := mload(0x40)
            mstore(0x40, add(bitsPtr, 0x4))

            for {
                let i := 0
            } lt(i, 0x20) {
                i := add(i, 0x1)
            } {
                let currentByte := byte(i, target_)

                if gt(currentByte, 0) {
                    coefficientStartIndex := i

                    if gt(currentByte, 0x80) {
                        coefficientStartIndex := sub(coefficientStartIndex, 0x1)
                    }

                    break
                }
            }

            mstore8(bitsPtr, sub(0x20, coefficientStartIndex))

            for {
                let i := 0
            } lt(i, coefficientLength) {
                i := add(i, 0x1)
            } {
                mstore8(add(bitsPtr, add(i, 0x1)), byte(add(coefficientStartIndex, i), target_))
            }

            bits_ := mload(bitsPtr)
        }
    }

    function _roundTarget(bytes32 currentTarget_) private pure returns (bytes32 roundedTarget_) {
        assembly {
            let coefficientLength := 0x3
            let coefficientEndIndex := 0

            for {
                let i := 0
            } lt(i, 0x20) {
                i := add(i, 0x1)
            } {
                let currentByte := byte(i, currentTarget_)

                if gt(currentByte, 0) {
                    coefficientEndIndex := add(i, coefficientLength)

                    if gt(currentByte, 0x80) {
                        coefficientEndIndex := sub(coefficientEndIndex, 0x1)
                    }

                    break
                }
            }

            let keepBits := mul(sub(0x20, coefficientEndIndex), 8)
            let mask := not(sub(shl(keepBits, 1), 1))

            roundedTarget_ := and(currentTarget_, mask)
        }
    }
}
