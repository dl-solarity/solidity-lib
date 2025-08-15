// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {LibBytes} from "solady/src/utils/LibBytes.sol";

import {EndianConverter} from "../utils/EndianConverter.sol";

/**
 * @notice A library for parsing Bitcoin transactions.
 * Provides functions for parsing, formatting, and transaction ID calculation
 */
library TxParser {
    using LibBytes for bytes;
    using EndianConverter for *;

    struct Transaction {
        TransactionInput[] inputs;
        TransactionOutput[] outputs;
        uint32 version;
        uint32 locktime;
        bool hasWitness;
    }

    struct TransactionInput {
        bytes32 previousHash;
        uint32 previousIndex;
        uint32 sequence;
        bytes script;
        bytes[] witnesses;
    }

    struct TransactionOutput {
        uint64 value;
        bytes script;
    }

    error UnsupportedVersion(uint32 version);
    error InvalidFlag(uint8 flag);
    error BufferOverflow();

    /**
     * @notice Calculate transaction ID (hash without witness data)
     * @param data_ The raw transaction data
     * @return The transaction ID
     */
    function calculateTxId(bytes calldata data_) internal pure returns (bytes32) {
        return _doubleSHA256(data_);
    }

    /**
     * @notice Parse a complete transaction from raw bytes
     * @param data_ The raw transaction data
     * @return tx_ The parsed transaction
     * @return consumed_ Number of bytes consumed
     */
    function parseTransaction(
        bytes calldata data_
    ) internal pure returns (Transaction memory tx_, uint256 consumed_) {
        uint256 position_;

        _checkForBufferOverflow(position_ + 4, data_.length);

        tx_.version = uint32(bytes4(data_[position_:position_ + 4])).uint32LEtoBE();

        position_ += 4;

        if (tx_.version != 1 && tx_.version != 2) {
            revert UnsupportedVersion(tx_.version);
        }

        uint256 inputCount_;
        uint256 lenSize_;

        (inputCount_, lenSize_) = _parseCuint(data_, position_);

        if (inputCount_ == 0) {
            tx_.hasWitness = true;
            ++position_;

            if (position_ >= data_.length) {
                revert InvalidFlag(0);
            }

            if (uint8(data_[position_]) != 1) {
                revert InvalidFlag(uint8(data_[position_]));
            }

            ++position_;

            (inputCount_, lenSize_) = _parseCuint(data_, position_);
        }

        position_ += lenSize_;

        tx_.inputs = new TransactionInput[](inputCount_);

        for (uint256 i = 0; i < inputCount_; ++i) {
            uint256 inputConsumed_;

            (tx_.inputs[i], inputConsumed_) = _parseTransactionInput(data_, position_);

            position_ += inputConsumed_;
        }

        uint256 outputCount_;
        (outputCount_, lenSize_) = _parseCuint(data_, position_);

        position_ += lenSize_;
        tx_.outputs = new TransactionOutput[](outputCount_);

        for (uint256 i = 0; i < outputCount_; ++i) {
            uint256 outputConsumed_;

            (tx_.outputs[i], outputConsumed_) = _parseTransactionOutput(data_, position_);

            position_ += outputConsumed_;
        }

        if (tx_.hasWitness) {
            for (uint256 i = 0; i < inputCount_; ++i) {
                uint256 witnessCount_;

                (witnessCount_, lenSize_) = _parseCuint(data_, position_);

                position_ += lenSize_;
                tx_.inputs[i].witnesses = new bytes[](witnessCount_);

                for (uint256 j = 0; j < witnessCount_; ++j) {
                    uint256 witnessLen_;

                    (witnessLen_, lenSize_) = _parseCuint(data_, position_);

                    position_ += lenSize_;

                    _checkForBufferOverflow(position_ + witnessLen_, data_.length);

                    tx_.inputs[i].witnesses[j] = data_.slice(position_, position_ + witnessLen_);

                    position_ += witnessLen_;
                }
            }
        }

        _checkForBufferOverflow(position_ + 4, data_.length);

        tx_.locktime = uint32(bytes4(data_[position_:position_ + 4])).uint32LEtoBE();

        position_ += 4;

        consumed_ = position_;
    }

    /**
     * @notice Format a transaction into raw bytes
     * @param tx_ The transaction to format
     * @param withWitness_ Whether to include witness data
     * @return The formatted transaction bytes
     */
    function formatTransaction(
        Transaction calldata tx_,
        bool withWitness_
    ) internal pure returns (bytes memory) {
        bool includeWitness_ = withWitness_ && tx_.hasWitness;

        bytes memory result_ = abi.encodePacked(tx_.version.uint32BEtoLE());

        if (includeWitness_) {
            result_ = abi.encodePacked(result_, uint8(0), uint8(1));
        }

        uint256 txInputsLength_ = tx_.inputs.length;
        result_ = abi.encodePacked(result_, formatCuint(uint64(txInputsLength_)));

        for (uint256 i = 0; i < txInputsLength_; ++i) {
            result_ = abi.encodePacked(result_, _formatTransactionInput(tx_.inputs[i]));
        }

        uint256 txOutputsLength_ = tx_.outputs.length;
        result_ = abi.encodePacked(result_, formatCuint(uint64(txOutputsLength_)));

        for (uint256 i = 0; i < txOutputsLength_; ++i) {
            result_ = abi.encodePacked(result_, _formatTransactionOutput(tx_.outputs[i]));
        }

        if (includeWitness_) {
            for (uint256 i = 0; i < txInputsLength_; ++i) {
                uint256 witnessesLength_ = tx_.inputs[i].witnesses.length;
                result_ = abi.encodePacked(result_, formatCuint(uint64(witnessesLength_)));

                for (uint256 j = 0; j < witnessesLength_; ++j) {
                    result_ = abi.encodePacked(
                        result_,
                        formatCuint(uint64(tx_.inputs[i].witnesses[j].length)),
                        tx_.inputs[i].witnesses[j]
                    );
                }
            }
        }

        result_ = abi.encodePacked(result_, tx_.locktime);

        return result_;
    }

    /**
     * @notice Checks whether bytes may be a valid Bitcoin transaction
     * @param data_ The raw transaction data
     * @return Whether the transaction is valid
     */
    function isTransaction(bytes memory data_) internal pure returns (bool) {
        if (data_.length < 60) {
            return false;
        }

        {
            uint256 version_ = uint8(bytes1(data_[0]));

            if (version_ < 1 || version_ > 2) {
                return false;
            }
        }

        if (bytes1(data_[1]) != bytes1(0)) return false;
        if (bytes1(data_[2]) != bytes1(0)) return false;
        if (bytes1(data_[3]) != bytes1(0)) return false;

        uint256 offset_ = 4;

        uint256 inputCount_;
        uint256 lenSize_;
        (inputCount_, lenSize_) = _parseCuint(data_, offset_);

        bool hasWitness_;

        if (inputCount_ == 0) {
            hasWitness_ = true;
            ++offset_;

            if (uint8(data_[offset_]) != 1) {
                return false;
            }

            ++offset_;

            (inputCount_, lenSize_) = _parseCuint(data_, offset_);
        }

        offset_ += lenSize_;

        // the locktime at the end has a fixed length, so we can already take it into account
        uint256 sizeWithoutLocktime_ = data_.length - 4;

        // previousHash: 32 bytes, previousIndex: 4 bytes, script ≥ 1 byte, sequence: 4 bytes
        if (inputCount_ * (32 + 4 + 1 + 4) + offset_ >= sizeWithoutLocktime_) {
            return false;
        }

        uint256 scriptLen_;

        for (uint256 i = 0; i < inputCount_; ++i) {
            offset_ += 32; // previousHash
            offset_ += 4; // previousIndex

            (scriptLen_, lenSize_) = _parseCuint(data_, offset_);

            offset_ += scriptLen_ + lenSize_;

            if (offset_ >= sizeWithoutLocktime_) {
                return false;
            }

            offset_ += 4; // sequence
        }

        uint256 outputCount_;
        (outputCount_, lenSize_) = _parseCuint(data_, offset_);

        // value: 8 bytes, script length ≥ 1 byte
        if (outputCount_ * (8 + 1) + offset_ > sizeWithoutLocktime_) {
            return false;
        }

        offset_ += lenSize_;

        for (uint256 i = 0; i < outputCount_; ++i) {
            offset_ += 8; // value

            (scriptLen_, lenSize_) = _parseCuint(data_, offset_);

            offset_ += scriptLen_ + lenSize_;

            if (offset_ > sizeWithoutLocktime_) {
                return false;
            }
        }

        if (hasWitness_) {
            for (uint256 i = 0; i < inputCount_; ++i) {
                uint256 witnessCount_;

                (witnessCount_, lenSize_) = _parseCuint(data_, offset_);

                offset_ += lenSize_;

                if (witnessCount_ + offset_ > sizeWithoutLocktime_) {
                    return false;
                }

                for (uint256 j = 0; j < witnessCount_; ++j) {
                    uint256 witnessLen_;

                    (witnessLen_, lenSize_) = _parseCuint(data_, offset_);

                    offset_ += lenSize_ + witnessLen_;

                    if (offset_ > sizeWithoutLocktime_) {
                        return false;
                    }
                }
            }
        }

        if (offset_ != sizeWithoutLocktime_) {
            return false;
        }

        return true;
    }

    /**
     * @notice Parse a compact unsigned integer (Bitcoin's variable length encoding)
     * @param data_ The byte calldata array containing the cuint in little-endian encoding
     * @return value_ The parsed integer value
     * @return consumed_ Number of bytes consumed
     */
    function parseCuint(
        bytes calldata data_
    ) internal pure returns (uint64 value_, uint8 consumed_) {
        return _parseCuint(data_, 0);
    }

    /**
     * @notice Format an integer as a compact unsigned integer
     * @dev Returns bytes in little-endian encoding
     * @param value_ The integer to encode
     * @return The encoded bytes
     */
    function formatCuint(uint64 value_) internal pure returns (bytes memory) {
        if (value_ < 0xfd) {
            return abi.encodePacked(uint8(value_));
        }

        if (value_ <= 0xffff) {
            return abi.encodePacked(uint8(0xfd), uint16(value_).uint16BEtoLE());
        }

        if (value_ <= 0xffffffff) {
            return abi.encodePacked(uint8(0xfe), uint32(value_).uint32BEtoLE());
        }

        return abi.encodePacked(uint8(0xff), value_.uint64BEtoLE());
    }

    /**
     * @notice Parse a transaction input from raw bytes
     */
    function _parseTransactionInput(
        bytes calldata data_,
        uint256 offset_
    ) private pure returns (TransactionInput memory input_, uint256 consumed_) {
        uint256 position_ = offset_;

        _checkForBufferOverflow(position_ + 32, data_.length);

        input_.previousHash = (bytes32(data_.slice(position_, position_ + 32))).bytes32LEtoBE();

        position_ += 32;

        _checkForBufferOverflow(position_ + 4, data_.length);

        input_.previousIndex = uint32(bytes4(data_[position_:position_ + 4])).uint32LEtoBE();

        position_ += 4;

        uint256 scriptLen_;
        uint256 lenSize_;

        (scriptLen_, lenSize_) = _parseCuint(data_, position_);

        position_ += lenSize_;

        _checkForBufferOverflow(position_ + scriptLen_, data_.length);

        input_.script = data_.slice(position_, position_ + scriptLen_);

        position_ += scriptLen_;

        _checkForBufferOverflow(position_ + 4, data_.length);

        input_.sequence = uint32(bytes4(data_[position_:position_ + 4])).uint32LEtoBE();

        position_ += 4;

        consumed_ = position_ - offset_;
    }

    /**
     * @notice Parse a transaction output from raw bytes
     */
    function _parseTransactionOutput(
        bytes calldata data_,
        uint256 offset_
    ) private pure returns (TransactionOutput memory output_, uint256 consumed_) {
        uint256 position_ = offset_;

        _checkForBufferOverflow(position_ + 8, data_.length);

        output_.value = uint64(bytes8(data_.slice(position_, position_ + 8))).uint64LEtoBE();

        position_ += 8;

        uint256 scriptLen_;
        uint256 lenSize_;

        (scriptLen_, lenSize_) = _parseCuint(data_, position_);

        position_ += lenSize_;

        _checkForBufferOverflow(position_ + scriptLen_, data_.length);

        output_.script = data_.slice(position_, position_ + scriptLen_);

        position_ += scriptLen_;

        consumed_ = position_ - offset_;
    }

    /**
     * @notice Format a transaction input into raw bytes
     */
    function _formatTransactionInput(
        TransactionInput calldata input_
    ) private pure returns (bytes memory) {
        bytes memory prevHash_ = abi.encodePacked((input_.previousHash).bytes32BEtoLE());
        bytes memory previousIndex_ = abi.encodePacked(input_.previousIndex.uint32BEtoLE());
        bytes memory sequence_ = abi.encodePacked(input_.sequence.uint32BEtoLE());

        return
            abi.encodePacked(
                prevHash_,
                previousIndex_,
                formatCuint(uint64(input_.script.length)),
                input_.script,
                sequence_
            );
    }

    /**
     * @notice Format a transaction output into raw bytes
     */
    function _formatTransactionOutput(
        TransactionOutput calldata output_
    ) private pure returns (bytes memory) {
        bytes memory value_ = abi.encodePacked(output_.value.uint64BEtoLE());

        return
            abi.encodePacked(value_, formatCuint(uint64(output_.script.length)), output_.script);
    }

    function _parseCuint(
        bytes memory data_,
        uint256 offset_
    ) private pure returns (uint64 value_, uint8 consumed_) {
        _checkForBufferOverflow(offset_ + 1, data_.length);

        uint8 firstByte_ = uint8(data_[offset_]);

        if (firstByte_ < 0xfd) {
            return (uint8(firstByte_), 1);
        }

        if (firstByte_ == 0xfd) {
            _checkForBufferOverflow(offset_ + 3, data_.length);

            value_ = uint16(bytes2(data_.slice(offset_ + 1, offset_ + 3))).uint16LEtoBE();

            return (value_, 3);
        }

        if (firstByte_ == 0xfe) {
            _checkForBufferOverflow(offset_ + 5, data_.length);

            value_ = uint32(bytes4(data_.slice(offset_ + 1, offset_ + 5))).uint32LEtoBE();

            return (value_, 5);
        }

        _checkForBufferOverflow(offset_ + 9, data_.length);

        value_ = uint64(bytes8(data_.slice(offset_ + 1, offset_ + 9))).uint64LEtoBE();

        return (value_, 9);
    }

    /**
     * @notice Checks whether byte position will exceed data length
     */
    function _checkForBufferOverflow(uint256 positionToCheck_, uint256 dataLength_) private pure {
        if (positionToCheck_ > dataLength_) {
            revert BufferOverflow();
        }
    }

    /**
     * @notice Double sha256 hashing
     */
    function _doubleSHA256(bytes memory data_) private pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}
