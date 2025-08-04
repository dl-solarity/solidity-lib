// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {LibBit} from "solady/src/utils/LibBit.sol";
import {LibBytes} from "solady/src/utils/LibBytes.sol";

/**
 * @notice A library with useful functions for working with Bitcoin.
 * Provides functions for converting between little-endian and big-endian formats, as well as for hashing
 */
library BitcoinHelper {
    using LibBit for uint256;
    using LibBytes for bytes;

    /**
     * @notice Converts between little-endian and big-endian formats
     * @param input_ The bytes to reverse
     * @return The reversed bytes
     */
    function reverseBytes(bytes32 input_) internal pure returns (bytes32) {
        return bytes32(leBytes32ToUint256(input_));
    }

    /**
     * @notice Converts between little-endian and big-endian formats
     * @param input_ The bytes32 to reverse
     * @return The reversed bytes
     */
    function reverseBytes32ToBytes(bytes32 input_) internal pure returns (bytes memory) {
        return abi.encodePacked(leBytes32ToUint256(input_));
    }

    /**
     * @notice Converts between little-endian and big-endian formats
     * @param input_ The uint32 to reverse
     * @return The reversed uint32
     */
    function reverseUint32(uint32 input_) internal pure returns (uint32) {
        return
            ((input_ & 0x000000FF) << 24) |
            ((input_ & 0x0000FF00) << 8) |
            ((input_ & 0x00FF0000) >> 8) |
            ((input_ & 0xFF000000) >> 24);
    }

    /**
     * @notice Converts bytes in little-endian encoding to big-endian uint32
     * @param input_ The bytes to reverse
     * @return The uint32 result
     */
    function leBytesToUint32(bytes calldata input_) internal pure returns (uint32) {
        return uint32(leBytesToUint256(input_));
    }

    /**
     * @notice Converts bytes32 in little-endian encoding to big-endian uint32
     * @param input_ The bytes32 to reverse
     * @return The uint32 result
     */
    function leBytes32ToUint32(bytes32 input_) internal pure returns (uint32) {
        return uint32(leBytes32ToUint256(input_));
    }

    /**
     * @notice Converts bytes in little-endian encoding to big-endian uint256
     * @param input_ The bytes to reverse
     * @return The uint256 result
     */
    function leBytesToUint256(bytes calldata input_) internal pure returns (uint256) {
        return leBytes32ToUint256(bytes32(input_));
    }

    /**
     * @notice Converts bytes in little-endian encoding to big-endian uint256
     * @param input_ The bytes32 to reverse
     * @return The uint256 result
     */
    function leBytes32ToUint256(bytes32 input_) internal pure returns (uint256) {
        return uint256(input_).reverseBytes();
    }

    /**
     * @notice Converts array of bytes in little-endian encoding to big-endian uint32
     * @return The uint32 result
     */
    function leBytes1ToUint32(
        bytes1 byte1,
        bytes1 byte2,
        bytes1 byte3,
        bytes1 byte4
    ) internal pure returns (uint32) {
        return
            uint32(
                uint8(byte1) |
                    (uint256(uint8(byte2)) << 8) |
                    (uint256(uint8(byte3)) << 16) |
                    (uint256(uint8(byte4)) << 24)
            );
    }

    /**
     * @notice Converts uint32 to little-endian bytes
     * @param input_ The uint32 to convert
     * @return The bytes in little-endian encoding
     */
    function uint32ToBytesLE(uint32 input_) internal pure returns (bytes memory) {
        return (abi.encodePacked(uint256(input_).reverseBytes())).slice(0, 4);
    }

    /**
     * @notice Converts int64 to little-endian bytes
     * @param input_ The int64 to convert
     * @return The bytes in little-endian encoding
     */
    function int64ToBytesLE(int64 input_) internal pure returns (bytes memory) {
        return (abi.encodePacked(uint256(uint64(input_)).reverseBytes())).slice(0, 8);
    }
    /**
     * @notice Compute double SHA256 hash
     * @param data_ The data to hash
     * @return The hash result
     */
    function doubleSHA256(bytes memory data_) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}
