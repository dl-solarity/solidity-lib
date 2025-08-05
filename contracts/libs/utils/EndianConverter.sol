// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {LibBit} from "solady/src/utils/LibBit.sol";
import {LibBytes} from "solady/src/utils/LibBytes.sol";

/**
 * @notice A library with functions for converting between little-endian and big-endian formats
 */
library EndianConverter {
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

    function reverseUint16(uint16 input_) internal pure returns (uint16) {
        return ((input_ & 0x00FF) << 8) | ((input_ & 0xFF00) >> 8);
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

    function reverseUint64(uint64 input_) internal pure returns (uint64) {
        return
            ((input_ & 0x00000000000000FF) << 56) |
            ((input_ & 0x000000000000FF00) << 40) |
            ((input_ & 0x0000000000FF0000) << 24) |
            ((input_ & 0x00000000FF000000) << 8) |
            ((input_ & 0x000000FF00000000) >> 8) |
            ((input_ & 0x0000FF0000000000) >> 24) |
            ((input_ & 0x00FF000000000000) >> 40) |
            ((input_ & 0xFF00000000000000) >> 56);
    }

    function reverseUint128(uint128 input_) internal pure returns (uint128) {
        return
            ((input_ & 0x000000000000000000000000000000FF) << 120) |
            ((input_ & 0x0000000000000000000000000000FF00) << 104) |
            ((input_ & 0x00000000000000000000000000FF0000) << 88) |
            ((input_ & 0x000000000000000000000000FF000000) << 72) |
            ((input_ & 0x0000000000000000000000FF00000000) << 56) |
            ((input_ & 0x00000000000000000000FF0000000000) << 40) |
            ((input_ & 0x000000000000000000FF000000000000) << 24) |
            ((input_ & 0x0000000000000000FF00000000000000) << 8) |
            ((input_ & 0x00000000000000FF0000000000000000) >> 8) |
            ((input_ & 0x000000000000FF000000000000000000) >> 24) |
            ((input_ & 0x0000000000FF00000000000000000000) >> 40) |
            ((input_ & 0x00000000FF0000000000000000000000) >> 56) |
            ((input_ & 0x000000FF000000000000000000000000) >> 72) |
            ((input_ & 0x0000FF00000000000000000000000000) >> 88) |
            ((input_ & 0x00FF0000000000000000000000000000) >> 104) |
            ((input_ & 0xFF000000000000000000000000000000) >> 120);
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
     * @notice Converts uint32 to little-endian bytes
     * @param input_ The uint32 to convert
     * @return The bytes in little-endian encoding
     */
    function uint32ToBytesLE(uint32 input_) internal pure returns (bytes memory) {
        return (abi.encodePacked(uint256(input_).reverseBytes())).slice(0, 4);
    }

    /**
     * @notice Converts uint64 to little-endian bytes
     * @param input_ The uint64 to convert
     * @return The bytes in little-endian encoding
     */
    function uint64ToBytesLE(uint64 input_) internal pure returns (bytes memory) {
        return (abi.encodePacked(uint256(input_).reverseBytes())).slice(0, 8);
    }
}
