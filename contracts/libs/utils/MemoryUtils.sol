// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title MemoryUtils
 * @notice A library that provides utility functions for memory manipulation in Solidity.
 */
library MemoryUtils {
    /**
     * @notice Copies the contents of the source string to the destination string.
     *
     * @param source_ The source string to copy from.
     * @return destination_ The newly allocated string.
     */
    function copy(string memory source_) internal view returns (string memory destination_) {
        destination_ = new string(bytes(source_).length);

        unsafeCopy(getDataPointer(source_), getDataPointer(destination_), bytes(source_).length);
    }

    /**
     * @notice Copies the contents of the source bytes to the destination bytes.
     *
     * @param source_ The source bytes to copy from.
     * @return destination_ The newly allocated bytes.
     */
    function copy(bytes memory source_) internal view returns (bytes memory destination_) {
        destination_ = new bytes(source_.length);

        unsafeCopy(getDataPointer(source_), getDataPointer(destination_), source_.length);
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
    function unsafeCopy(
        uint256 sourcePointer_,
        uint256 destinationPointer_,
        uint256 size_
    ) internal view {
        assembly {
            pop(staticcall(gas(), 4, sourcePointer_, size_, destinationPointer_, size_))
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(bytes memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(string memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(bytes[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(string[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(uint256[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(address[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(string memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(bytes memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(bytes[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(string[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(uint256[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(address[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }
}
