// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** @title Oracle
 * @notice Provides price and liquidity data useful for a wide variety of system designs. Adopted for Solidity 0.8.0.
 * In comparison to Oracle lib from Uniswap V3, liquidity logic is partially removed as it isn't needed for Oracle contract.
 * secondsPerLiquidityCumulativeX128 set to zero or empty array.
 * This contract used only for correct simulation of UniswapV3PoolMock.
 * @dev Instances of stored oracle data, "observations", are collected in the oracle array
 * Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
 * maximum length of the oracle array. New slots will be added when the array is fully populated.
 * Observations are overwritten when the full length of the oracle array is populated.
 */
library Oracle {
    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    /** @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
     * @param self The stored oracle array
     * @param time_ The time of the oracle initialization, via block.timestamp truncated to uint32
     * @return cardinality_ The number of populated elements in the oracle array
     * @return cardinalityNext_ The new length of the oracle array, independent of population
     */
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

    /** @notice Writes an oracle observation to the array
     * @dev Writable at most once per block. Index represents the most recently written element. cardinality_ and index_ must be tracked externally.
     * If the index_ is at the end of the allowable array length (according to cardinality_), and the next cardinality_
     * is greater than the current one, cardinality_ may be increased. This restriction is created to preserve ordering.
     * @param self The stored oracle array
     * @param index_ The index_ of the observation that was most recently written to the observations array
     * @param blockTimestamp_ The timestamp of the new observation
     * @param tick_ The active tick at the time of the new observation
     * @param cardinality_ The number of populated elements in the oracle array
     * @param cardinalityNext_ The new length of the oracle array, independent of population
     * @return indexUpdated_ The new index_ of the most recently written element in the oracle array
     * @return cardinalityUpdated_ The new cardinality_ of the oracle array
     */
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

    /** @notice Prepares the oracle array to store up to `next` observations
     * @param self The stored oracle array
     * @param current_ The current next cardinality_ of the oracle array
     * @param next_ The proposed next cardinality_ which will be populated in the oracle array
     * @return next_ The next cardinality_ which will be populated in the oracle
     */
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

    /** @dev Reverts if an observation at or before the desired observation timestamp does not exist.
     * 0 may be passed as `secondsAgo' to return the current cumulative values.
     * If called with a timestamp falling between two observations, returns the counterfactual accumulator values
     * at exactly the timestamp between the two observations.
     * @param self The stored oracle array
     * @param time_ The current block timestamp
     * @param secondsAgo_ The amount of time to look back, in seconds, at which point to return an observation
     * @param tick_ The current tick
     * @param index_ The index_ of the observation that was most recently written to the observations array
     * @param cardinality_ The number of populated elements in the oracle array
     * @return tickCumulative_ The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
     */
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
                // we're at the left boundary
                return beforeOrAt_.tickCumulative;
            } else if (target_ == atOrAfter_.blockTimestamp) {
                // we're at the right boundary
                return atOrAfter_.tickCumulative;
            } else {
                // we're in the middle
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

    /** @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
     * @dev Reverts if `secondsAgos` > oldest observation
     * @param self The stored oracle array
     * @param time_ The current block.timestamp
     * @param secondsAgos_ Each amount of time to look back, in seconds, at which point to return an observation
     * @param tick_ The current tick
     * @param index_ The index_ of the observation that was most recently written to the observations array
     * @param cardinality_ The number of populated elements in the oracle array
     * @return tickCumulatives_ The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
     */
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

    /** @notice Fetches the observations beforeOrAt_ and atOrAfter_ a given target_, i.e. where [beforeOrAt_, atOrAfter_] is satisfied
     * @dev Assumes there is at least 1 initialized observation.
     * Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
     * @param self The stored oracle array
     * @param time_ The current block.timestamp
     * @param target_ The timestamp at which the reserved observation should be for
     * @param tick_ The active tick at the time of the returned or simulated observation
     * @param index_ The index_ of the observation that was most recently written to the observations array
     * @param cardinality_ The number of populated elements in the oracle array
     * @return beforeOrAt_ The observation which occurred at, or before, the given timestamp
     * @return atOrAfter_ The observation which occurred at, or after, the given timestamp
     */
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

            // if we've reached this point, we have to binary search
            return binarySearch(self, time_, target_, index_, cardinality_);
        }
    }

    /** @notice Fetches the observations beforeOrAt_ and atOrAfter_ a target_, i.e. where [beforeOrAt_, atOrAfter_] is satisfied.
     * The result may be the same observation, or adjacent observations.
     * @dev The answer must be contained in the array, used when the target_ is located within the stored observation
     * boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
     * @param self The stored oracle array
     * @param time_ The current block.timestamp
     * @param target_ The timestamp at which the reserved observation should be for
     * @param index_ The index_ of the observation that was most recently written to the observations array
     * @param cardinality_ The number of populated elements in the oracle array
     * @return beforeOrAt_ The observation recorded before, or at, the target_
     * @return atOrAfter_ The observation recorded at, or after, the target_
     */
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

    /** @notice comparator for 32-bit timestamps
     * @dev safe for 0 or 1 overflows, timestamp1_ and timestamp2_ _must_ be chronologically before or equal to time
     * @param time_ A timestamp truncated to 32 bits
     * @param timestamp1_ A comparison timestamp from which to determine the relative position of `time`
     * @param timestamp2_ From which to determine the relative position of `time`
     * @return bool Whether `timestamp1_` is chronologically <= `timestamp2_`
     */
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

    /** @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
     * @dev blockTimestamp _must_ be chronologically equal to or greater than last_.blockTimestamp, safe for 0 or 1 overflows
     * @param last_ The specified observation to be transformed
     * @param blockTimestamp_ The timestamp of the new observation
     * @param tick_ The active tick at the time of the new observation
     * @return Observation The newly populated observation
     */
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
