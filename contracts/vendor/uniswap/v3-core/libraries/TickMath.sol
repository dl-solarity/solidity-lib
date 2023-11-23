// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** @title Math library for computing sqrt prices from ticks and vice versa
 * @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
 * prices between 2**-128 and 2**128
 */
library TickMath {
    uint24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /**
     * @notice Calculates sqrt(1.0001^tick) * 2^96
     * @dev Throws if |tick| > max tick
     * @param tick_ the input tick for the above formula
     * @return sqrtPriceX96_ a Fixed point Q64.96 number representing the sqrt of the ratio of the two assets
     * (currency1/currency0) at the given tick
     */
    function getSqrtRatioAtTick(int24 tick_) internal pure returns (uint160 sqrtPriceX96_) {
        unchecked {
            uint256 absTick_ = tick_ < 0 ? uint256(-int256(tick_)) : uint256(int256(tick_));
            require(absTick_ <= uint256(MAX_TICK), "TickMath: invalid tick");

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
     * @param sqrtPriceX96_ the sqrt ratio for which to compute the tick as a Q64.96
     * @return tick_ the greatest tick for which the ratio is less than or equal to the input ratio
     */
    function getTickAtSqrtRatio(uint160 sqrtPriceX96_) internal pure returns (int24 tick_) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            require(
                sqrtPriceX96_ >= MIN_SQRT_RATIO && sqrtPriceX96_ < MAX_SQRT_RATIO,
                "TickMath: sqrtPriceX96 not in range"
            );
            uint256 ratio_ = uint256(sqrtPriceX96_) << 32;

            uint256 tempRatio_ = ratio_;
            uint256 msb_ = 0; //Most significant bit

            assembly {
                let f := shl(7, gt(tempRatio_, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(6, gt(tempRatio_, 0xFFFFFFFFFFFFFFFF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(5, gt(tempRatio_, 0xFFFFFFFF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(4, gt(tempRatio_, 0xFFFF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(3, gt(tempRatio_, 0xFF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(2, gt(tempRatio_, 0xF))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := shl(1, gt(tempRatio_, 0x3))
                msb_ := or(msb_, f)
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                let f := gt(tempRatio_, 0x1)
                msb_ := or(msb_, f)
            }

            if (msb_ >= 128) tempRatio_ = ratio_ >> (msb_ - 127);
            else tempRatio_ = ratio_ << (127 - msb_);

            int256 log_2 = (int256(msb_) - 128) << 64;

            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(63, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(62, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(61, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(60, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(59, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(58, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(57, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(56, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(55, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(54, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(53, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(52, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(51, f))
                tempRatio_ := shr(f, tempRatio_)
            }
            assembly {
                tempRatio_ := shr(127, mul(tempRatio_, tempRatio_))
                let f := shr(128, tempRatio_)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001_ = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow_ = int24(
                (log_sqrt10001_ - 3402992956809132418596140100660247210) >> 128
            );
            int24 tickHi_ = int24(
                (log_sqrt10001_ + 291339464771989622907027621153398088495) >> 128
            );

            tick_ = tickLow_ == tickHi_
                ? tickLow_
                : (getSqrtRatioAtTick(tickHi_) <= sqrtPriceX96_ ? tickHi_ : tickLow_);
        }
    }
}
