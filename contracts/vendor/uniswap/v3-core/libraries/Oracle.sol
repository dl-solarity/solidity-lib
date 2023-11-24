// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** @title Oracle
 * @notice Provides price and liquidity data
 */
library Oracle {
    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    function initialize(
        Observation[65535] storage self,
        uint32 time
    ) internal returns (uint16 cardinality, uint16 cardinalityNext) {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            initialized: true
        });
        return (1, 1);
    }

    function grow(
        Observation[65535] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        unchecked {
            // no-op if the passed next value isn't greater than the current next value
            if (next <= current) return current;
            // store in each slot to prevent fresh SSTOREs in swaps
            // this data will not be used because the initialized boolean is still false
            for (uint16 i = current; i < next; i++) {
                self[i].blockTimestamp = 1;
            }
            return next;
        }
    }

    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        unchecked {
            Observation memory last = self[index];

            // early return if we've already written an observation this block
            if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

            // if the conditions are right, we can bump the cardinality_
            if (cardinalityNext > cardinality && index == (cardinality - 1)) {
                cardinalityUpdated = cardinalityNext;
            } else {
                cardinalityUpdated = cardinality;
            }

            indexUpdated = (index + 1) % cardinalityUpdated;

            self[indexUpdated] = transform(last, blockTimestamp, tick);
        }
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative) {
        unchecked {
            if (secondsAgo == 0) {
                Observation memory last = self[index];

                if (last.blockTimestamp != time) last = transform(last, time, tick);
                return last.tickCumulative;
            }

            uint32 target = time - secondsAgo;

            (
                Observation memory beforeOrAt,
                Observation memory atOrAfter
            ) = getSurroundingObservations(self, time, target, tick, index, cardinality);

            if (target == beforeOrAt.blockTimestamp) {
                return beforeOrAt.tickCumulative;
            } else if (target == atOrAfter.blockTimestamp) {
                return atOrAfter.tickCumulative;
            } else {
                uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
                uint32 targetDelta = target - beforeOrAt.blockTimestamp;

                return
                    beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) /
                        int56(uint56(observationTimeDelta))) *
                    int56(uint56(targetDelta));
            }
        }
    }

    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56[] memory tickCumulatives) {
        unchecked {
            tickCumulatives = new int56[](secondsAgos.length);

            for (uint256 i = 0; i < secondsAgos.length; i++) {
                (tickCumulatives[i]) = observeSingle(
                    self,
                    time,
                    secondsAgos[i],
                    tick,
                    index,
                    cardinality
                );
            }
        }
    }

    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        unchecked {
            uint256 left = (index + 1) % cardinality; // oldest observation
            uint256 right = left + cardinality - 1; // newest observation
            uint256 mid;
            while (true) {
                mid = (left + right) / 2;

                beforeOrAt = self[mid % cardinality];

                // we've landed on an uninitialized tick, keep searching higher (more recently)
                if (!beforeOrAt.initialized) {
                    left = mid + 1;
                    continue;
                }

                atOrAfter = self[(mid + 1) % cardinality];

                bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

                // check if we've found the answer!
                if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

                if (!targetAtOrAfter) right = mid - 1;
                else left = mid + 1;
            }
        }
    }

    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        unchecked {
            // optimistically set before to the newest observation
            beforeOrAt = self[index];

            // if the target_ is chronologically at or after the newest observation, we can early return
            if (lte(time, beforeOrAt.blockTimestamp, target)) {
                if (beforeOrAt.blockTimestamp == target) {
                    // if newest observation equals target_, we're in the same block, so we can ignore atOrAfter_
                    return (beforeOrAt, atOrAfter);
                } else {
                    // otherwise, we need to transform
                    return (beforeOrAt, transform(beforeOrAt, target, tick));
                }
            }

            // now, set before to the oldest observation
            beforeOrAt = self[(index + 1) % cardinality];
            if (!beforeOrAt.initialized) beforeOrAt = self[0];

            return binarySearch(self, time, target, index, cardinality);
        }
    }

    function lte(uint32 time, uint32 timestamp1, uint32 timestamp2) private pure returns (bool) {
        unchecked {
            // if there hasn't been overflow, no need to adjust
            if (timestamp1 <= time && timestamp2 <= time) return timestamp1 <= timestamp2;

            uint256 aAdjusted = timestamp1 > time ? timestamp1 : timestamp1 + 2 ** 32;
            uint256 bAdjusted = timestamp2 > time ? timestamp2 : timestamp2 + 2 ** 32;

            return aAdjusted <= bAdjusted;
        }
    }

    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick
    ) private pure returns (Observation memory) {
        unchecked {
            return
                Observation({
                    blockTimestamp: blockTimestamp,
                    tickCumulative: last.tickCumulative +
                        int56(tick) *
                        int56(uint56(blockTimestamp - last.blockTimestamp)),
                    secondsPerLiquidityCumulativeX128: 0,
                    initialized: true
                });
        }
    }
}
