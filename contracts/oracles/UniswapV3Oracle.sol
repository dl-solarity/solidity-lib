// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {ArrayHelper} from "../libs/arrays/ArrayHelper.sol";

//import {Oracle} from "@uniswap/v4-periphery/contracts/libraries/Oracle.sol";

//coverage for lib functions?
//codestyle
//add/fix comments

/**
 * @notice UniswapV3Oracle module
 *
 * A contract for retrieving prices from Uniswap V3 pools.
 */
abstract contract UniswapV3Oracle is Initializable {
    using Math for uint256;

    int24 internal constant MAX_TICK = 887272;

    IUniswapV3Factory public uniswapV3Factory;

    /**
     * @notice Constructor
     * @param uniswapV3Factory_ the Uniswap V3 factory
     */
    function __OracleV3_init(address uniswapV3Factory_) internal onlyInitializing {
        uniswapV3Factory = IUniswapV3Factory(uniswapV3Factory_);
    }

    /**
     * @notice The function to retrieve the price of a token following the configured route
     * @param path_ The path of token address, the last one is token in which price will be returned
     * @param fees_ The array of fees for particular pools
     * @param amount_ The amount of baseToken_
     * @param period_ The time period
     * @return returns the price of start token in quote token
     */
    function getPriceOfTokenInToken(
        address[] memory path_, //last is QuoteToken
        uint24[] memory fees_,
        uint256 amount_,
        uint32 period_
    ) external view returns (uint256) {
        uint256 pathLength_ = path_.length;

        require(pathLength_ > 1, "UniswapV3Oracle: invalid path");
        require(pathLength_ == fees_.length + 1, "UniswapV3Oracle: path/fee lengths do not match");

        for (uint256 i = 0; i < pathLength_ - 1; i++) {
            address nextToken_ = path_[i + 1];

            (uint256 price_, uint32 time_) = _getPriceOfTokenInToken(path_[i], nextToken_, fees_[i], period_); 
            //array of times to return?
            //or select smallest one

            amount_ = price_ * amount_;

            //amount_ = price_.mulDiv(amount_, uint128(10) ** 18);
        }

        return (amount_);

        //return price_.mulDiv(amount_, uint128(10) ** uint128(ERC20(quoteToken_).decimals()));
    }

    //if same tokens - return same value or revert? bsc we dont have such pool
    //return *10 in power of decimals ?
    function _getPriceOfTokenInToken(
        address baseToken_,
        address quoteToken_,
        uint24 fee_,
        uint32 period_
    ) internal view returns (uint256, uint32) {
        //console.logUint(uint256(ERC20(quoteToken_).decimals()));
        uint128 base_ = 1; //?

        if (baseToken_ == quoteToken_) {  //?
            return (base_, period_);
        } else {
            address pool_ = uniswapV3Factory.getPool(baseToken_, quoteToken_, fee_);

            require(pool_ != address(0), "UniswapV3Oracle: such pool doesn't exist");

            uint32 oldest_ = _findOldestObservation(pool_); //oldest available timestamp

            if(oldest_ <= block.timestamp - period_) { //if there is observation with older timestamp that needed, its okay
                return (_getQuoteAtTick(_consult(pool_, period_), base_, baseToken_, quoteToken_), period_);
            } else {
                return (_getQuoteAtTick(_consult(pool_, uint32(block.timestamp) - oldest_), base_, baseToken_, quoteToken_), period_);
            }            
        }
    }

    function _findOldestObservation(
        address pool_        
    ) internal view returns (uint32) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool_)
            .slot0();

        uint256 newIndex;
        if (observationIndex + 1 < observationCardinality) {
            newIndex = observationIndex + 1;
        } else {
            newIndex = 0;
        }

        (uint32 blockTimestamp,
            ,
            ,
            bool initialized //should we check if initialized? must be due to previous logic, but
        ) = IUniswapV3Pool(pool_).observations(newIndex);

        return blockTimestamp;
    }

    /**
     * @notice Fetches time-weighted average tick using Uniswap V3 oracle
     * @param pool_ Address of Uniswap V3 pool that we want to observe
     * @param period_ Number of seconds in the past to start calculating time-weighted average
     * @return timeWeightedAverageTick_ The time-weighted average tick from (block.timestamp - period) to block.timestamp
     */
    function _consult(address pool_, uint32 period_) private view returns (int24) {
        require(period_ > 0, "UniswapV3Oracle: period can't be 0");

        uint32[] memory secondAgos_ = new uint32[](2);
        secondAgos_[0] = period_;
        secondAgos_[1] = 0;

        (int56[] memory tickCumulatives_, ) = IUniswapV3Pool(pool_).observe(secondAgos_);
        int56 tickCumulativesDelta_ = tickCumulatives_[1] - tickCumulatives_[0];

        int24 timeWeightedAverageTick_ = int24(tickCumulativesDelta_ / int(uint256(period_)));

        // Always round to negative infinity
        if (tickCumulativesDelta_ < 0 && (tickCumulativesDelta_ % int(uint256(period_)) != 0))
            timeWeightedAverageTick_--;

        return timeWeightedAverageTick_;
    }

    /**
     * @notice Given a tick and a token amount, calculates the amount of token received in exchange
     * @param tick_ Tick value used to calculate the quote
     * @param baseAmount_ Amount of token to be converted
     * @param baseToken_ Address of an ERC20 token contract used as the baseAmount_ denomination
     * @param quoteToken_ Address of an ERC20 token contract used as the quoteAmount_ denomination
     * @return quoteAmount_ Amount of quoteToken_ received for baseAmount_ of baseToken_
     */
    function _getQuoteAtTick(
        int24 tick_,
        uint128 baseAmount_,
        address baseToken_,
        address quoteToken_
    ) private pure returns (uint256) {
        uint160 sqrtRatioX96_ = _getSqrtRatioAtTick(tick_);
        uint256 quoteAmount_;

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

        return quoteAmount_;
    }

    function _getSqrtRatioAtTick(int24 tick_) private pure returns (uint160 sqrtPriceX96_) {
        unchecked {
            uint256 absTick_ = tick_ < 0 ? uint256(-int256(tick_)) : uint256(int256(tick_));
            require(absTick_ <= uint256(int256(MAX_TICK)), "UniswapV3Oracle: invalid tick");

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
}
