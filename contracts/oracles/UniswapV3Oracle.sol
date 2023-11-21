// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {TickHelper} from "./external-modules-uniswapV3/TickHelper.sol";

/**
 * @notice UniswapV3Oracle module
 *
 * A contract for retrieving prices from Uniswap V3 pools.
 * Works by calculating and saving tickCumulative in every observation,
 * so some historical prices from time-weighted tick can be retrieved.
 *
 * In case required period of time is unreachable, tick is taken from oldest available observation.
 */
abstract contract UniswapV3Oracle is Initializable {
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
     * @dev The function returns price in quote token decimals. If amount is zero, returns (0, 0).
     * @param path_ the path of token address, the last one is token in which price will be returned
     * @param fees_ the array of fees for particular pools
     * @param amount_ the amount of baseToken_
     * @param period_ the time period
     * @return amount_ the price of start token in quote token
     * @return minPeriod_ the oldest period for which there is an observation in case period_ time ago there was no observation
     */
    function getPriceOfTokenInToken(
        address[] memory path_,
        uint24[] memory fees_,
        uint128 amount_,
        uint32 period_
    ) public view returns (uint128, uint32) {
        uint256 pathLength_ = path_.length;

        require(pathLength_ > 1, "UniswapV3Oracle: invalid path");
        require(pathLength_ == fees_.length + 1, "UniswapV3Oracle: path/fee lengths do not match");
        require(
            block.timestamp > period_,
            "UniswapV3Oracle: period larger than current timestamp"
        );
        require(period_ > 0, "UniswapV3Oracle: period can't be 0");

        if (amount_ == 0) {
            return (0, 0);
        }

        uint32 minPeriod_ = period_;

        for (uint256 i = 0; i < pathLength_ - 1; i++) {
            (uint256 price_, uint32 time_) = _getPriceOfTokenInToken(
                path_[i],
                path_[i + 1],
                amount_,
                fees_[i],
                period_
            );

            amount_ = SafeCast.toUint128(price_);

            if (minPeriod_ > time_) {
                minPeriod_ = time_;
            }
        }

        return (amount_, minPeriod_);
    }

    /**
     * @notice Function to get timestamp from the oldest available observation
     */
    function _findOldestObservation(address pool_) internal view returns (uint32) {
        (, , uint16 observationIndex_, uint16 observationCardinality_, , , ) = IUniswapV3Pool(
            pool_
        ).slot0();

        require(observationCardinality_ > 0, "UniswapV3Oracle: pool is not initialized");

        (uint32 blockTimestamp_, , , bool initialized_) = IUniswapV3Pool(pool_).observations(
            (observationIndex_ + 1) % observationCardinality_
        );

        if (!initialized_) {
            (blockTimestamp_, , , ) = IUniswapV3Pool(pool_).observations(0);
        }

        return blockTimestamp_;
    }

    /**
     * @notice The private function to get the price of a token inside a pool
     * @dev Returns price multplied by 10 in power of decimals of the quoteToken_
     */
    function _getPriceOfTokenInToken(
        address baseToken_,
        address quoteToken_,
        uint128 amount_,
        uint24 fee_,
        uint32 period_
    ) private view returns (uint256, uint32) {
        if (baseToken_ == quoteToken_) {
            return (amount_, period_);
        }

        address pool_ = uniswapV3Factory.getPool(baseToken_, quoteToken_, fee_);

        require(pool_ != address(0), "UniswapV3Oracle: such pool doesn't exist");

        uint32 oldest_ = _findOldestObservation(pool_); //oldest available timestamp

        require(
            oldest_ != block.timestamp,
            "UniswapV3Oracle: the oldest observation is on current block"
        );

        period_ = uint32(Math.min(uint32(block.timestamp) - oldest_, period_));

        return (
            TickHelper.getQuoteAtTick(
                TickHelper.consult(pool_, period_),
                amount_,
                baseToken_,
                quoteToken_
            ),
            period_
        );
    }
}
