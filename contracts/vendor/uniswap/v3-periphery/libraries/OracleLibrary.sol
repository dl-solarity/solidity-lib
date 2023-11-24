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
     * @param pool address of the pool that we want to observe
     * @param secondsAgo number of seconds in the past from which to calculate the time-weighted means
     * @return timeWeightedAverageTick the arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
     */
    function consult(address pool, uint32 secondsAgo) internal view returns (int24) {
        unchecked {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = secondsAgo;
            secondsAgos[1] = 0;

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

            int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int(uint256(secondsAgo)));

            // Always round to negative infinity
            if (
                tickCumulativesDelta < 0 && (tickCumulativesDelta % int(uint256(secondsAgo)) != 0)
            ) {
                timeWeightedAverageTick--;
            }

            return timeWeightedAverageTick;
        }
    }

    /**
     * @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
     * @param pool address of Uniswap V3 pool that we want to observe
     * @return secondsAgo the number of seconds ago of the oldest observation stored for the pool
     */
    function getOldestObservationSecondsAgo(
        address pool
    ) internal view returns (uint32 secondsAgo) {
        unchecked {
            (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(
                pool
            ).slot0();
            require(observationCardinality > 0, "not initialized");

            (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool)
                .observations((observationIndex + 1) % observationCardinality);

            // The next index might not be initialized if the cardinality is in the process of increasing
            // In this case the oldest observation is always in index 0
            if (!initialized) {
                (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
            }

            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /**
     * @notice Given a tick and a token amount, calculates the amount of token received in exchange
     * @param tick tick value used to calculate the quote
     * @param baseAmount amount of token to be converted
     * @param baseToken address of an ERC20 token contract used as the baseAmount denomination
     * @param quoteToken address of an ERC20 token contract used as the quoteAmount denomination
     * @return quoteAmount amount of quoteToken received for baseAmount of baseToken
     */
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        unchecked {
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

            // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
            if (sqrtRatioX96 <= type(uint128).max) {
                uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;

                quoteAmount = baseToken < quoteToken
                    ? Math.mulDiv(ratioX192, baseAmount, 1 << 192)
                    : Math.mulDiv(1 << 192, baseAmount, ratioX192);
            } else {
                uint256 ratioX128 = Math.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);

                quoteAmount = baseToken < quoteToken
                    ? Math.mulDiv(ratioX128, baseAmount, 1 << 128)
                    : Math.mulDiv(1 << 128, baseAmount, ratioX128);
            }
        }
    }
}
