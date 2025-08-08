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
     * @param returnInBEFormat_ Whether to return the hashes in big-endian encoding
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
            version: uint32(bytes4(blockHeaderRaw_[0:4])),
            prevBlockHash: bytes32(blockHeaderRaw_[4:36]),
            merkleRoot: bytes32(blockHeaderRaw_[36:68]),
            time: uint32(bytes4(blockHeaderRaw_[68:72])),
            bits: bytes4(blockHeaderRaw_[72:76]),
            nonce: uint32(bytes4(blockHeaderRaw_[76:80]))
        });

        blockHash_ = _getBlockHeaderHash(blockHeaderRaw_);

        if (returnInBEFormat_) {
            headerData_.version = headerData_.version.uint32LEtoBE();
            headerData_.prevBlockHash = headerData_.prevBlockHash.bytes32LEtoBE();
            headerData_.merkleRoot = headerData_.merkleRoot.bytes32LEtoBE();
            headerData_.time = headerData_.time.uint32LEtoBE();
            headerData_.bits = bytes4(uint32(headerData_.bits).uint32LEtoBE());
            headerData_.nonce = headerData_.nonce.uint32LEtoBE();

            blockHash_ = blockHash_.bytes32LEtoBE();
        }
    }

    /**
     * @notice Converts a `HeaderData` structure back into its raw byte representation.
     * This function reconstructs the original byte sequence of the block header
     * @param headerData_ The `HeaderData` structure to convert
     * @param inputInBEFormat_ Whether headerData_ is expected to be in big-endian encoding
     * @return The raw byte representation of the block header
     */
    function toRawBytes(
        HeaderData memory headerData_,
        bool inputInBEFormat_
    ) internal pure returns (bytes memory) {
        if (inputInBEFormat_) {
            return
                abi.encodePacked(
                    headerData_.version.uint32BEtoLE(),
                    headerData_.prevBlockHash.bytes32BEtoLE(),
                    headerData_.merkleRoot.bytes32BEtoLE(),
                    headerData_.time.uint32BEtoLE(),
                    (uint32(headerData_.bits)).uint32BEtoLE(),
                    headerData_.nonce.uint32BEtoLE()
                );
        }

        return
            abi.encodePacked(
                headerData_.version,
                headerData_.prevBlockHash,
                headerData_.merkleRoot,
                headerData_.time,
                headerData_.bits,
                headerData_.nonce
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
