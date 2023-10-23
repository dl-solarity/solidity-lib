// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/*
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './NoDelegateCall.sol';

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
*/
//import '@uniswap/v3-core/contracts/libraries/Tick.sol';
//import '@uniswap/v3-core/contracts/libraries/TickBitmap.sol';
//import '@uniswap/v3-core/contracts/libraries/Position.sol';

//import '@uniswap/v3-core/contracts/libraries/Oracle.sol';

//import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
//import '@uniswap/v3-core/contracts/libraries/FixedPoint128.sol';
//import '@uniswap/v3-core/contracts/libraries/TransferHelper.sol';
//import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
//import '@uniswap/v3-core/contracts/libraries/LiquidityMath.sol';
//import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
//import '@uniswap/v3-core/contracts/libraries/SwapMath.sol';

//import '@uniswap/v3-core/contracts/interfaces/IUniswapV3PoolDeployer.sol';
//import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
//import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
/*
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol';*/

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract UniswapV3PoolMock {

    //hardcoded
    function observe(
        uint32[] calldata secondAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        )
    {
        require(secondAgos[0] < block.timestamp, "period is bigger than current timestamp");

        int56[] memory array_ = new int56[](2);
        array_[0] = int56(uint56(secondAgos[0]));
        array_[1] = array_[0] - 1;

        return (array_, new uint160[](0));
    }

    /*
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;*/
    //using Oracle for Oracle.Observation[65535];

    //using Tick for mapping(int24 => Tick.Info);
    //using TickBitmap for mapping(int16 => uint256);
    /*
    address public immutable factory;
    
    address public immutable token0;
    
    address public immutable token1;
   
    uint24 public immutable fee;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
   
    Slot0 public slot0;

    //mapping(int24 => Tick.Info) public ticks;


    //Oracle.Observation[65535] public observations;

    /*
    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    constructor() {
        int24 _tickSpacing;
        (factory, token0, token1, fee, _tickSpacing) = IUniswapV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }*/
    

}
