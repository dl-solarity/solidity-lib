// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {Oracle} from "../../../oracles/external-modules-UniswapV3Oracle/Oracle.sol";
import {TickHelper} from "../../../oracles/external-modules-UniswapV3Oracle/TickHelper.sol";

contract UniswapV3PoolMock {
    using Oracle for Oracle.Observation[65535];

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    Slot0 public slot0;
    Oracle.Observation[65535] public observations;

    function initialize(uint160 sqrtPriceX96) external {
        int24 tick = TickHelper.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });
    }

    function addObservation(int24 tick_) external {
        (slot0.observationIndex, slot0.observationCardinality) = observations.write(
            slot0.observationIndex,
            _blockTimestamp(),
            slot0.tick,
            slot0.observationCardinality,
            slot0.observationCardinalityNext
        );

        slot0.tick = tick_;
    }

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external {
        slot0.observationCardinalityNext = observations.grow(
            slot0.observationCardinalityNext,
            observationCardinalityNext
        );
    }

    function observe(
        uint32[] calldata secondAgos_
    )
        external
        view
        returns (
            int56[] memory tickCumulatives_,
            uint160[] memory secondsPerLiquidityCumulativeX128s_
        )
    {
        return (
            observations.observe(
                _blockTimestamp(),
                secondAgos_,
                slot0.tick,
                slot0.observationIndex,
                slot0.observationCardinality
            ),
            new uint160[](secondAgos_.length)
        );
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }
}
