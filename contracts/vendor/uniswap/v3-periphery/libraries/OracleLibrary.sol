// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "../../v3-core/libraries/TickMath.sol";

/** @title Oracle library
 * @notice Provides functions to integrate with V3 pool oracle
 */
library OracleLibrary {
    /**
     * @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
     * @dev Doesn't do anything with liquidity (while original OracleLibrary library in v3-periphery do)
     * @param pool_ address of the pool that we want to observe
     * @param period_ number of seconds in the past from which to calculate the time-weighted means
     * @return timeWeightedAverageTick_ the arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
     */
    function consult(address pool_, uint32 period_) internal view returns (int24) {
        unchecked {
            uint32[] memory secondAgos_ = new uint32[](2);
            secondAgos_[0] = period_;
            secondAgos_[1] = 0;

            (int56[] memory tickCumulatives_, ) = IUniswapV3Pool(pool_).observe(secondAgos_);

            int56 tickCumulativesDelta_ = tickCumulatives_[1] - tickCumulatives_[0];

            int24 timeWeightedAverageTick_ = int24(tickCumulativesDelta_ / int(uint256(period_)));

            // Always round to negative infinity
            if (
                tickCumulativesDelta_ < 0 && (tickCumulativesDelta_ % int(uint256(period_)) != 0)
            ) {
                timeWeightedAverageTick_--;
            }

            return timeWeightedAverageTick_;
        }
    }

    /**
     * @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
     * @param pool_ address of Uniswap V3 pool that we want to observe
     * @return longestPeriod_ the number of seconds ago of the oldest observation stored for the pool
     */
    function getOldestObservationSecondsAgo(
        address pool_
    ) internal view returns (uint32 longestPeriod_) {
        unchecked {
            (, , uint16 observationIndex_, uint16 observationCardinality_, , , ) = IUniswapV3Pool(
                pool_
            ).slot0();

            require(observationCardinality_ > 0, "OracleLibrary: pool is not initialized");

            (uint32 observationTimestamp_, , , bool initialized_) = IUniswapV3Pool(pool_)
                .observations((observationIndex_ + 1) % observationCardinality_);

            // The next index might not be initialized if the cardinality is in the process of increasing
            // In this case the oldest observation is always in index 0
            if (!initialized_) {
                (observationTimestamp_, , , ) = IUniswapV3Pool(pool_).observations(0);
            }

            longestPeriod_ = uint32(block.timestamp) - observationTimestamp_;
        }
    }

    /**
     * @notice Given a tick and a token amount, calculates the amount of token received in exchange
     * @param tick_ tick value used to calculate the quote
     * @param baseAmount_ amount of token to be converted
     * @param baseToken_ address of an ERC20 token contract used as the baseAmount denomination
     * @param quoteToken_ address of an ERC20 token contract used as the quoteAmount denomination
     * @return quoteAmount_ amount of quoteToken received for baseAmount of baseToken
     */
    function getQuoteAtTick(
        int24 tick_,
        uint128 baseAmount_,
        address baseToken_,
        address quoteToken_
    ) internal pure returns (uint256 quoteAmount_) {
        unchecked {
            uint160 sqrtRatioX96_ = TickMath.getSqrtRatioAtTick(tick_);

            // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
            if (sqrtRatioX96_ <= type(uint128).max) {
                uint256 ratioX192_ = uint256(sqrtRatioX96_) * sqrtRatioX96_;

                quoteAmount_ = baseToken_ < quoteToken_
                    ? Math.mulDiv(ratioX192_, baseAmount_, 1 << 192)
                    : Math.mulDiv(1 << 192, baseAmount_, ratioX192_);
            } else {
                uint256 ratioX128_ = Math.mulDiv(sqrtRatioX96_, sqrtRatioX96_, 1 << 64);

                quoteAmount_ = baseToken_ < quoteToken_
                    ? Math.mulDiv(ratioX128_, baseAmount_, 1 << 128)
                    : Math.mulDiv(1 << 128, baseAmount_, ratioX128_);
            }
        }
    }
}
