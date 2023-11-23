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
        uint32 time_
    ) internal returns (uint16 cardinality_, uint16 cardinalityNext_) {
        self[0] = Observation({
            blockTimestamp: time_,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            initialized: true
        });
        return (1, 1);
    }

    function grow(
        Observation[65535] storage self,
        uint16 current_,
        uint16 next_
    ) internal returns (uint16) {
        unchecked {
            // no-op if the passed next value isn't greater than the current next value
            if (next_ <= current_) return current_;
            // store in each slot to prevent fresh SSTOREs in swaps
            // this data will not be used because the initialized boolean is still false
            for (uint16 i = current_; i < next_; i++) {
                self[i].blockTimestamp = 1;
            }
            return next_;
        }
    }

    function write(
        Observation[65535] storage self,
        uint16 index_,
        uint32 blockTimestamp_,
        int24 tick_,
        uint16 cardinality_,
        uint16 cardinalityNext_
    ) internal returns (uint16 indexUpdated_, uint16 cardinalityUpdated_) {
        unchecked {
            Observation memory last_ = self[index_];

            // early return if we've already written an observation this block
            if (last_.blockTimestamp == blockTimestamp_) return (index_, cardinality_);

            // if the conditions are right, we can bump the cardinality_
            if (cardinalityNext_ > cardinality_ && index_ == (cardinality_ - 1)) {
                cardinalityUpdated_ = cardinalityNext_;
            } else {
                cardinalityUpdated_ = cardinality_;
            }

            indexUpdated_ = (index_ + 1) % cardinalityUpdated_;

            self[indexUpdated_] = transform(last_, blockTimestamp_, tick_);
        }
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time_,
        uint32 secondsAgo_,
        int24 tick_,
        uint16 index_,
        uint16 cardinality_
    ) internal view returns (int56 tickCumulative_) {
        unchecked {
            if (secondsAgo_ == 0) {
                Observation memory last_ = self[index_];

                if (last_.blockTimestamp != time_) last_ = transform(last_, time_, tick_);
                return last_.tickCumulative;
            }

            uint32 target_ = time_ - secondsAgo_;

            (
                Observation memory beforeOrAt_,
                Observation memory atOrAfter_
            ) = getSurroundingObservations(self, time_, target_, tick_, index_, cardinality_);

            if (target_ == beforeOrAt_.blockTimestamp) {
                return beforeOrAt_.tickCumulative;
            } else if (target_ == atOrAfter_.blockTimestamp) {
                return atOrAfter_.tickCumulative;
            } else {
                uint32 observationTimeDelta_ = atOrAfter_.blockTimestamp -
                    beforeOrAt_.blockTimestamp;
                uint32 targetDelta_ = target_ - beforeOrAt_.blockTimestamp;

                return
                    beforeOrAt_.tickCumulative +
                    ((atOrAfter_.tickCumulative - beforeOrAt_.tickCumulative) /
                        int56(uint56(observationTimeDelta_))) *
                    int56(uint56(targetDelta_));
            }
        }
    }

    function observe(
        Observation[65535] storage self,
        uint32 time_,
        uint32[] memory secondsAgos_,
        int24 tick_,
        uint16 index_,
        uint16 cardinality_
    ) internal view returns (int56[] memory tickCumulatives_) {
        unchecked {
            tickCumulatives_ = new int56[](secondsAgos_.length);

            for (uint256 i = 0; i < secondsAgos_.length; i++) {
                (tickCumulatives_[i]) = observeSingle(
                    self,
                    time_,
                    secondsAgos_[i],
                    tick_,
                    index_,
                    cardinality_
                );
            }
        }
    }

    function binarySearch(
        Observation[65535] storage self,
        uint32 time_,
        uint32 target_,
        uint16 index_,
        uint16 cardinality_
    ) private view returns (Observation memory beforeOrAt_, Observation memory atOrAfter_) {
        unchecked {
            uint256 left_ = (index_ + 1) % cardinality_; // oldest observation
            uint256 right_ = left_ + cardinality_ - 1; // newest observation
            uint256 mid_;
            while (true) {
                mid_ = (left_ + right_) / 2;

                beforeOrAt_ = self[mid_ % cardinality_];

                // we've landed on an uninitialized tick, keep searching higher (more recently)
                if (!beforeOrAt_.initialized) {
                    left_ = mid_ + 1;
                    continue;
                }

                atOrAfter_ = self[(mid_ + 1) % cardinality_];

                bool targetAtOrAfter_ = lte(time_, beforeOrAt_.blockTimestamp, target_);

                // check if we've found the answer!
                if (targetAtOrAfter_ && lte(time_, target_, atOrAfter_.blockTimestamp)) break;

                if (!targetAtOrAfter_) right_ = mid_ - 1;
                else left_ = mid_ + 1;
            }
        }
    }

    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time_,
        uint32 target_,
        int24 tick_,
        uint16 index_,
        uint16 cardinality_
    ) private view returns (Observation memory beforeOrAt_, Observation memory atOrAfter_) {
        unchecked {
            // optimistically set before to the newest observation
            beforeOrAt_ = self[index_];

            // if the target_ is chronologically at or after the newest observation, we can early return
            if (lte(time_, beforeOrAt_.blockTimestamp, target_)) {
                if (beforeOrAt_.blockTimestamp == target_) {
                    // if newest observation equals target_, we're in the same block, so we can ignore atOrAfter_
                    return (beforeOrAt_, atOrAfter_);
                } else {
                    // otherwise, we need to transform
                    return (beforeOrAt_, transform(beforeOrAt_, target_, tick_));
                }
            }

            // now, set before to the oldest observation
            beforeOrAt_ = self[(index_ + 1) % cardinality_];
            if (!beforeOrAt_.initialized) beforeOrAt_ = self[0];

            return binarySearch(self, time_, target_, index_, cardinality_);
        }
    }

    function lte(
        uint32 time_,
        uint32 timestamp1_,
        uint32 timestamp2_
    ) private pure returns (bool) {
        unchecked {
            // if there hasn't been overflow, no need to adjust
            if (timestamp1_ <= time_ && timestamp2_ <= time_) return timestamp1_ <= timestamp2_;

            uint256 aAdjusted_ = timestamp1_ > time_ ? timestamp1_ : timestamp1_ + 2 ** 32;
            uint256 bAdjusted_ = timestamp2_ > time_ ? timestamp2_ : timestamp2_ + 2 ** 32;

            return aAdjusted_ <= bAdjusted_;
        }
    }

    function transform(
        Observation memory last_,
        uint32 blockTimestamp_,
        int24 tick_
    ) private pure returns (Observation memory) {
        unchecked {
            return
                Observation({
                    blockTimestamp: blockTimestamp_,
                    tickCumulative: last_.tickCumulative +
                        int56(tick_) *
                        int56(uint56(blockTimestamp_ - last_.blockTimestamp)),
                    secondsPerLiquidityCumulativeX128: 0,
                    initialized: true
                });
        }
    }
}
