// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title MemoryUtils
 * @notice A library that provides utility functions for memory manipulation in Solidity.
 */
library MemoryUtils {
    /**
     * @notice Copies the contents of the source string to the destination string.
     * @dev This function reverts if the source string size is greater than the destination string size.
     *
     * @param source_ The source string to copy from.
     * @param destination_ The destination string to copy to.
     */
    function copyTo(string memory source_, string memory destination_) internal view {
        require(
            getSize(source_) <= getSize(destination_),
            "MemoryUtils: destination string size is too small"
        );

        unsafeMemoryCopy(getPointer(source_), getPointer(destination_), getSize(source_));
    }

    /**
     * @notice Copies the contents of the source bytes to the destination bytes.
     * @dev This function reverts if the source bytes length is greater than the destination bytes length.
     *
     * @param source_ The source bytes to copy from.
     * @param destination_ The destination bytes to copy to.
     */
    function copyTo(bytes memory source_, bytes memory destination_) internal view {
        require(
            source_.length <= destination_.length,
            "MemoryUtils: destination bytes length is too small"
        );

        unsafeMemoryCopy(getPointer(source_), getPointer(destination_), source_.length);
    }

    /**
     * @notice Copies memory from one location to another efficiently via identity precompile.
     * @param sourcePointer_ The offset in the memory from which to copy.
     * @param destinationPointer_ The offset in the memory where the result will be copied.
     * @param size_ The size of the memory to copy.
     *
     * @dev This function does not account for free memory pointer and should be used with caution.
     *
     * This signature of calling identity precompile is:
     * staticcall(gas(), address(0x04), argsOffset, argsSize, retOffset, retSize)
     */
    function unsafeMemoryCopy(
        uint256 sourcePointer_,
        uint256 destinationPointer_,
        uint256 size_
    ) internal view {
        assembly {
            pop(
                staticcall(
                    gas(),
                    4,
                    add(sourcePointer_, 32),
                    size_,
                    add(destinationPointer_, 32),
                    size_
                )
            )
        }
    }

    /**
     * @notice Returns the memory pointer of the given bytes data.
     */
    function getPointer(bytes memory data) internal pure returns (uint256 pointer) {
        assembly {
            pointer := data
        }
    }

    /**
     * @notice Returns the memory pointer of the given string data.
     */
    function getPointer(string memory data) internal pure returns (uint256 pointer) {
        assembly {
            pointer := data
        }
    }

    /**
     * @notice Returns the size of the given string data.
     */
    function getSize(string memory data) internal pure returns (uint256 size) {
        assembly {
            size := mload(data)
        }
    }
}
