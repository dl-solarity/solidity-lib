// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The library to work with memory
 */
library MemoryUtils {
    /**
     * @notice The function to copy memory from one location to another
     * @param destinationOffset_ offset in the memory where the result will be copied.
     * @param offset_ offset in the memory from which to copy.
     * @param size_ size to copy (must be % 32 == 0).
     *
     * TODO: check identity precompile
     * TODO: handle non-%32 size
     *
     * IMPORTANT: This function does not account for free memory pointer and should be used with caution.
     */
    function copyMemory(uint256 destinationOffset_, uint256 offset_, uint256 size_) internal pure {
        assembly {
            for {
                let i := 0
            } lt(i, size_) {
                i := add(i, 32)
            } {
                mstore(add(destinationOffset_, i), mload(add(offset_, i)))
            }
        }
    }
}
