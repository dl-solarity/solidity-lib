// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TickHelper} from "./external-modules-UniswapV3Oracle/TickHelper.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

//coverage for lib functions
//codestyle
//import "hardhat/console.sol";

/**
 * @notice UniswapV3Oracle module
 *
 * A contract for retrieving prices from Uniswap V3 pools.
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
     * @param path_ The path of token address, the last one is token in which price will be returned
     * @param fees_ The array of fees for particular pools
     * @param amount_ The amount of baseToken_
     * @param period_ The time period
     * @return amount_ the price of start token in quote token
     * @return minPeriod_ the oldest period for which there is an observation in case period_ time ago there was no observation
     */
    function getPriceOfTokenInToken(
        address[] memory path_, //last is QuoteToken
        uint24[] memory fees_,
        uint256 amount_,
        uint32 period_
    ) external view returns (uint256, uint32) {
        uint256 pathLength_ = path_.length;

        require(pathLength_ > 1, "UniswapV3Oracle: invalid path");
        require(pathLength_ == fees_.length + 1, "UniswapV3Oracle: path/fee lengths do not match");
        require(
            block.timestamp > period_,
            "UniswapV3Oracle: period larger than current timestamp"
        );

        uint32 minPeriod_ = period_;

        for (uint256 i = 0; i < pathLength_ - 1; i++) {
            (uint256 price_, uint32 time_) = _getPriceOfTokenInToken(
                path_[i],
                path_[i + 1],
                fees_[i],
                period_
            );

            amount_ = price_ * amount_;
            if (minPeriod_ > time_) minPeriod_ = time_;
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

        uint256 newIndex_;
        if (observationIndex_ + 1 < observationCardinality_) {
            newIndex_ = observationIndex_ + 1;
        } else {
            newIndex_ = 0;
        }

        (
            uint32 blockTimestamp_, //should we check if initialized?
            ,
            ,

        ) = IUniswapV3Pool(pool_).observations(newIndex_);

        return blockTimestamp_;
    }

    /**
     * @notice The private function to get the price of a token inside a pool
     */
    function _getPriceOfTokenInToken(
        address baseToken_,
        address quoteToken_,
        uint24 fee_,
        uint32 period_
    ) private view returns (uint256, uint32) {
        uint128 base_ = 1;

        if (baseToken_ == quoteToken_) {
            return (base_, period_);
        } else {
            address pool_ = uniswapV3Factory.getPool(baseToken_, quoteToken_, fee_);

            require(pool_ != address(0), "UniswapV3Oracle: such pool doesn't exist");

            uint32 oldest_ = _findOldestObservation(pool_); //oldest available timestamp

            require(
                oldest_ != block.timestamp,
                "UniswapV3Oracle: the oldest observation is on current block"
            );

            if (oldest_ <= block.timestamp - period_) {
                return (
                    TickHelper.getQuoteAtTick(
                        TickHelper.consult(pool_, period_),
                        base_,
                        baseToken_,
                        quoteToken_
                    ),
                    period_
                );
            } else {
                uint32 newPeriod_ = uint32(block.timestamp) - oldest_;
                return (
                    TickHelper.getQuoteAtTick(
                        TickHelper.consult(pool_, newPeriod_),
                        base_,
                        baseToken_,
                        quoteToken_
                    ),
                    newPeriod_
                );
            }
        }
    }
}
