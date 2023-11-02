// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/**
 * Library to work with ticks at Uniswap V3
 * Combines function from TickMath and OracleLibrary adopted for Solidity 0.8.0
 */
library TickHelper {
    int24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /**
     * @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool. Adopted for Solidity 0.8.0
     * @dev Don't do anything with liquidity (as in original OracleLibrary library in v3-periphery)
     * @param pool_ Address of the pool that we want to observe
     * @param period_ Number of seconds in the past from which to calculate the time-weighted means
     * @return timeWeightedAverageTick_ The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
     */
    function consult(address pool_, uint32 period_) internal view returns (int24) {
        require(period_ > 0, "TickHelper: period can't be 0");

        uint32[] memory secondAgos_ = new uint32[](2);
        secondAgos_[0] = period_;
        secondAgos_[1] = 0;

        (int56[] memory tickCumulatives_, ) = IUniswapV3Pool(pool_).observe(secondAgos_);

        int56 tickCumulativesDelta_ = tickCumulatives_[1] - tickCumulatives_[0];

        int24 timeWeightedAverageTick_ = int24(tickCumulativesDelta_ / int(uint256(period_)));

        // Always round to negative infinity
        if (tickCumulativesDelta_ < 0 && (tickCumulativesDelta_ % int(uint256(period_)) != 0)) {
            timeWeightedAverageTick_--;
        }

        return timeWeightedAverageTick_;
    }

    /**
     * @notice Given a tick and a token amount, calculates the amount of token received in exchange. Adopted for Solidity 0.8.0
     * @param tick_ Tick value used to calculate the quote
     * @param baseAmount_ Amount of token to be converted
     * @param baseToken_ Address of an ERC20 token contract used as the baseAmount denomination
     * @param quoteToken_ Address of an ERC20 token contract used as the quoteAmount denomination
     * @return quoteAmount_ Amount of quoteToken received for baseAmount of baseToken
     */
    function getQuoteAtTick(
        int24 tick_,
        uint128 baseAmount_,
        address baseToken_,
        address quoteToken_
    ) internal pure returns (uint256 quoteAmount_) {
        uint160 sqrtRatioX96_ = getSqrtRatioAtTick(tick_);

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

    /**
     * @notice Calculates sqrt(1.0001^tick) * 2^96
     * @dev Throws if |tick| > max tick
     * @param tick_ The input tick for the above formula
     * @return sqrtPriceX96_ A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (currency1/currency0)
     * at the given tick
     */
    function getSqrtRatioAtTick(int24 tick_) internal pure returns (uint160 sqrtPriceX96_) {
        unchecked {
            uint256 absTick_ = tick_ < 0 ? uint256(-int256(tick_)) : uint256(int256(tick_));
            require(absTick_ <= uint256(int256(MAX_TICK)), "TickHelper: invalid tick");

            uint256 ratio_ = absTick_ & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick_ & 0x2 != 0) ratio_ = (ratio_ * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick_ & 0x4 != 0) ratio_ = (ratio_ * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick_ & 0x8 != 0) ratio_ = (ratio_ * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick_ & 0x10 != 0)
                ratio_ = (ratio_ * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick_ & 0x20 != 0)
                ratio_ = (ratio_ * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick_ & 0x40 != 0)
                ratio_ = (ratio_ * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick_ & 0x80 != 0)
                ratio_ = (ratio_ * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick_ & 0x100 != 0)
                ratio_ = (ratio_ * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick_ & 0x200 != 0)
                ratio_ = (ratio_ * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick_ & 0x400 != 0)
                ratio_ = (ratio_ * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick_ & 0x800 != 0)
                ratio_ = (ratio_ * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick_ & 0x1000 != 0)
                ratio_ = (ratio_ * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick_ & 0x2000 != 0)
                ratio_ = (ratio_ * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick_ & 0x4000 != 0)
                ratio_ = (ratio_ * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick_ & 0x8000 != 0)
                ratio_ = (ratio_ * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick_ & 0x10000 != 0)
                ratio_ = (ratio_ * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick_ & 0x20000 != 0)
                ratio_ = (ratio_ * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick_ & 0x40000 != 0) ratio_ = (ratio_ * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick_ & 0x80000 != 0) ratio_ = (ratio_ * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick_ > 0) ratio_ = type(uint256).max / ratio_;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96_ = uint160((ratio_ >> 32) + (ratio_ % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /**
     * @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
     * @dev Throws in case sqrtPriceX96_ < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
     * ever return.
     * @param sqrtPriceX96_ The sqrt ratio for which to compute the tick as a Q64.96
     * @return tick_ The greatest tick for which the ratio is less than or equal to the input ratio
     */
    function getTickAtSqrtRatio(uint160 sqrtPriceX96_) internal pure returns (int24 tick_) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96_ >= MIN_SQRT_RATIO && sqrtPriceX96_ < MAX_SQRT_RATIO,
            "TickHelper: not in range"
        );
        uint256 ratio_ = uint256(sqrtPriceX96_) << 32;

        uint256 r = ratio_;
        uint256 msb_ = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb_ := or(msb_, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb_ := or(msb_, f)
        }

        if (msb_ >= 128) r = ratio_ >> (msb_ - 127);
        else r = ratio_ << (127 - msb_);

        int256 log_2 = (int256(msb_) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001_ = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow_ = int24((log_sqrt10001_ - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi_ = int24((log_sqrt10001_ + 291339464771989622907027621153398088495) >> 128);

        tick_ = tickLow_ == tickHi_
            ? tickLow_
            : (getSqrtRatioAtTick(tickHi_) <= sqrtPriceX96_ ? tickHi_ : tickLow_);
    }
}
