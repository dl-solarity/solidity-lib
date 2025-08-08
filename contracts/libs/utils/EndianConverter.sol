// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {LibBit} from "solady/src/utils/LibBit.sol";

/**
 * @notice A library with functions for converting between little-endian and big-endian formats
 */
library EndianConverter {
    using LibBit for uint256;

    /**
     * @notice Converts big-endian bytes2 to little-endian
     * @param input_ The bytes2 to convert
     * @return The bytes2 in little-endian encoding
     */
    function bytes2BEtoLE(bytes2 input_) internal pure returns (bytes2) {
        return bytes2(_reverseUint16(uint16(input_)));
    }

    /**
     * @notice Converts big-endian bytes4 to little-endian
     * @param input_ The bytes4 to convert
     * @return The bytes4 in little-endian encoding
     */
    function bytes4BEtoLE(bytes4 input_) internal pure returns (bytes4) {
        return bytes4(_reverseUint32(uint32(input_)));
    }

    /**
     * @notice Converts big-endian bytes8 to little-endian
     * @param input_ The bytes8 to convert
     * @return The bytes8 in little-endian encoding
     */
    function bytes8BEtoLE(bytes8 input_) internal pure returns (bytes8) {
        return bytes8(_reverseUint64(uint64(input_)));
    }

    /**
     * @notice Converts big-endian bytes16 to little-endian
     * @param input_ The bytes16 to convert
     * @return The bytes16 in little-endian encoding
     */
    function bytes16BEtoLE(bytes16 input_) internal pure returns (bytes16) {
        return bytes16(_reverseUint128(uint128(input_)));
    }

    /**
     * @notice Converts big-endian bytes32 to little-endian
     * @param input_ The bytes32 to convert
     * @return The bytes32 in little-endian encoding
     */
    function bytes32BEtoLE(bytes32 input_) internal pure returns (bytes32) {
        return bytes32(uint256(input_).reverseBytes());
    }

    /**
     * @notice Converts little-endian bytes2 to big-endian
     * @param input_ The bytes2 to convert
     * @return The bytes2 in big-endian encoding
     */
    function bytes2LEtoBE(bytes2 input_) internal pure returns (bytes2) {
        return bytes2(_reverseUint16(uint16(input_)));
    }

    /**
     * @notice Converts little-endian bytes4 to big-endian
     * @param input_ The bytes4 to convert
     * @return The bytes4 in big-endian encoding
     */
    function bytes4LEtoBE(bytes4 input_) internal pure returns (bytes4) {
        return bytes4(_reverseUint32(uint32(input_)));
    }

    /**
     * @notice Converts little-endian bytes8 to big-endian
     * @param input_ The bytes8 to convert
     * @return The bytes8 in big-endian encoding
     */
    function bytes8LEtoBE(bytes8 input_) internal pure returns (bytes8) {
        return bytes8(_reverseUint64(uint64(input_)));
    }

    /**
     * @notice Converts little-endian bytes16 to big-endian
     * @param input_ The bytes16 to convert
     * @return The bytes16 in big-endian encoding
     */
    function bytes16LEtoBE(bytes16 input_) internal pure returns (bytes16) {
        return bytes16(_reverseUint128(uint128(input_)));
    }

    /**
     * @notice Converts little-endian bytes32 to big-endian
     * @param input_ The bytes32 to convert
     * @return The bytes32 in big-endian encoding
     */
    function bytes32LEtoBE(bytes32 input_) internal pure returns (bytes32) {
        return bytes32(uint256(input_).reverseBytes());
    }

    /**
     * @notice Converts big-endian uint16 to little-endian
     * @param input_ The uint16 to convert
     * @return The uint16 in little-endian encoding
     */
    function uint16BEtoLE(uint16 input_) internal pure returns (uint16) {
        return _reverseUint16(input_);
    }

    /**
     * @notice Converts big-endian uint32 to little-endian
     * @param input_ The uint32 to convert
     * @return The uint32 in little-endian encoding
     */
    function uint32BEtoLE(uint32 input_) internal pure returns (uint32) {
        return _reverseUint32(input_);
    }

    /**
     * @notice Converts big-endian uint64 to little-endian
     * @param input_ The uint64 to convert
     * @return The uint64 in little-endian encoding
     */
    function uint64BEtoLE(uint64 input_) internal pure returns (uint64) {
        return _reverseUint64(input_);
    }

    /**
     * @notice Converts big-endian uint128 to little-endian
     * @param input_ The uint128 to convert
     * @return The uint128 in little-endian encoding
     */
    function uint128BEtoLE(uint128 input_) internal pure returns (uint128) {
        return _reverseUint128(input_);
    }

    /**
     * @notice Converts big-endian uint256 to little-endian
     * @param input_ The uint256 to convert
     * @return The uint256 in little-endian encoding
     */
    function uint256BEtoLE(uint256 input_) internal pure returns (uint256) {
        return input_.reverseBytes();
    }

    /**
     * @notice Converts little-endian uint16 to big-endian
     * @param input_ The uint16 to convert
     * @return The uint16 in big-endian encoding
     */
    function uint16LEtoBE(uint16 input_) internal pure returns (uint16) {
        return _reverseUint16(input_);
    }

    /**
     * @notice Converts little-endian uint32 to big-endian
     * @param input_ The uint32 to convert
     * @return The uint32 in big-endian encoding
     */
    function uint32LEtoBE(uint32 input_) internal pure returns (uint32) {
        return _reverseUint32(input_);
    }

    /**
     * @notice Converts little-endian uint64 to big-endian
     * @param input_ The uint64 to convert
     * @return The uint64 in big-endian encoding
     */
    function uint64LEtoBE(uint64 input_) internal pure returns (uint64) {
        return _reverseUint64(input_);
    }

    /**
     * @notice Converts little-endian uint128 to big-endian
     * @param input_ The uint128 to convert
     * @return The uint128 in big-endian encoding
     */
    function uint128LEtoBE(uint128 input_) internal pure returns (uint128) {
        return _reverseUint128(input_);
    }

    /**
     * @notice Converts little-endian uint256 to big-endian
     * @param input_ The uint256 to convert
     * @return The uint256 in big-endian encoding
     */
    function uint256LEtoBE(uint256 input_) internal pure returns (uint256) {
        return input_.reverseBytes();
    }

    /**
     * @notice Converts between little-endian and big-endian formats
     */
    function _reverseUint16(uint16 input_) private pure returns (uint16) {
        return ((input_ & 0x00FF) << 8) | ((input_ & 0xFF00) >> 8);
    }

    /**
     * @notice Converts between little-endian and big-endian formats
     */
    function _reverseUint32(uint32 input_) private pure returns (uint32) {
        return
            ((input_ & 0x000000FF) << 24) |
            ((input_ & 0x0000FF00) << 8) |
            ((input_ & 0x00FF0000) >> 8) |
            ((input_ & 0xFF000000) >> 24);
    }

    /**
     * @notice Converts between little-endian and big-endian formats
     */
    function _reverseUint64(uint64 input_) private pure returns (uint64) {
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

    /**
     * @notice Converts between little-endian and big-endian formats
     */
    function _reverseUint128(uint128 input_) private pure returns (uint128) {
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
}
