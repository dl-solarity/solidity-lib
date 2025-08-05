// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {EndianConverter} from "../utils/EndianConverter.sol";

/**
 * @notice A utility library for handling Bitcoin block headers.
 * Provides functions for parsing, hashing, and converting block header data
 */
library BlockHeader {
    using EndianConverter for *;

    /**
     * @notice The standard length of a Bitcoin block header in bytes
     */
    uint256 public constant BLOCK_HEADER_DATA_LENGTH = 80;

    /**
     * @notice Represents the essential data contained within a Bitcoin block header
     * @param prevBlockHash The hash of the previous block
     * @param merkleRoot The Merkle root of the transactions in the block
     * @param version The block version number
     * @param time The block's timestamp
     * @param nonce The nonce used for mining
     * @param bits The encoded difficulty target for the block
     */
    struct HeaderData {
        bytes32 prevBlockHash;
        bytes32 merkleRoot;
        uint32 version;
        uint32 time;
        uint32 nonce;
        bytes4 bits;
    }

    /**
     * @notice Emitted when the provided block header data has an invalid length.
     * This error ensures that only correctly sized block headers are processed
     */
    error InvalidBlockHeaderDataLength();

    /**
     * @notice Parses a raw byte array into a structured `HeaderData` and calculates its hash.
     * It validates the length of the input and correctly decodes each field
     * @param blockHeaderRaw_ The raw bytes of the block header
     * @param returnInBEFormat_ Whether to return the hashes in big-endian format
     * @return headerData_ The parsed `HeaderData` structure
     * @return blockHash_ The calculated hash of the block header
     */
    function parseBlockHeader(
        bytes calldata blockHeaderRaw_,
        bool returnInBEFormat_
    ) internal pure returns (HeaderData memory headerData_, bytes32 blockHash_) {
        if (blockHeaderRaw_.length != BLOCK_HEADER_DATA_LENGTH)
            revert InvalidBlockHeaderDataLength();

        headerData_ = HeaderData({
            version: blockHeaderRaw_[0:4].leBytesToUint32(),
            prevBlockHash: bytes32(blockHeaderRaw_[4:36]),
            merkleRoot: bytes32(blockHeaderRaw_[36:68]),
            time: blockHeaderRaw_[68:72].leBytesToUint32(),
            bits: bytes4(blockHeaderRaw_[72:76]),
            nonce: blockHeaderRaw_[76:80].leBytesToUint32()
        });

        blockHash_ = _getBlockHeaderHash(blockHeaderRaw_);

        if (returnInBEFormat_) {
            headerData_.prevBlockHash = headerData_.prevBlockHash.reverseBytes();
            headerData_.merkleRoot = headerData_.merkleRoot.reverseBytes();
            headerData_.bits = bytes4(bytes32(headerData_.bits).leBytes32ToUint32());

            blockHash_ = blockHash_.reverseBytes();
        }
    }

    /**
     * @notice Converts a `HeaderData` structure back into its raw byte representation.
     * This function reconstructs the original byte sequence of the block header
     * @dev headerData_ is expected to be in big-endian encoding
     * @param headerData_ The `HeaderData` structure to convert
     * @return The raw byte representation of the block header
     */
    function toRawBytes(HeaderData memory headerData_) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                headerData_.version.reverseUint32(),
                headerData_.prevBlockHash.reverseBytes(),
                headerData_.merkleRoot.reverseBytes(),
                headerData_.time.reverseUint32(),
                (uint32(headerData_.bits)).reverseUint32(),
                headerData_.nonce.reverseUint32()
            );
    }

    /**
     * @notice Calculates the double SHA256 hash of a raw block header.
     * This is the standard method for deriving a Bitcoin block hash
     * @dev Returns block hash in little-endian encoding
     * @param blockHeaderRaw_ The raw bytes of the block header
     * @return The calculated block hash
     */
    function _getBlockHeaderHash(bytes calldata blockHeaderRaw_) private pure returns (bytes32) {
        bytes32 rawBlockHash_ = sha256(abi.encode(sha256(blockHeaderRaw_)));

        return rawBlockHash_;
    }
}
