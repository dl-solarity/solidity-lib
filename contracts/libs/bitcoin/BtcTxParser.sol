// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {LibBytes} from "solady/src/utils/LibBytes.sol";

import {EndianConverter} from "../utils/EndianConverter.sol";

/**
 * @notice A library for parsing Bitcoin transactions.
 * Provides functions for parsing, formatting, and transaction ID calculation
 */
library BtcTxParser {
    using LibBytes for bytes;
    using EndianConverter for *;

    struct Transaction {
        TransactionInput[] inputs;
        TransactionOutput[] outputs;
        int32 version;
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
        int64 value;
        bytes script;
    }

    error UnsupportedVersion(int32 version);
    error InvalidFlag(uint8 flag);
    error BufferOverflow();

    /**
     * @notice Parse a complete transaction from raw bytes
     * @param data_ The raw transaction data
     * @return tx_ The parsed transaction
     * @return consumed_ Number of bytes consumed
     */
    function parseTransaction(
        bytes calldata data_
    ) internal pure returns (Transaction memory tx_, uint256 consumed_) {
        uint256 position_ = 0;

        _checkForBufferOverflow(position_ + 4, data_.length);

        tx_.version = int32(
            EndianConverter.leBytes1ToUint32(
                data_[position_],
                data_[position_ + 1],
                data_[position_ + 2],
                data_[position_ + 3]
            )
        );

        position_ += 4;

        if (tx_.version != 1 && tx_.version != 2) {
            revert UnsupportedVersion(tx_.version);
        }

        uint256 inputCount_;
        uint256 lenSize_;

        (inputCount_, lenSize_) = parseCuint(data_, position_);

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

            (inputCount_, lenSize_) = parseCuint(data_, position_);
        }

        position_ += lenSize_;

        tx_.inputs = new TransactionInput[](inputCount_);

        for (uint256 i = 0; i < inputCount_; ++i) {
            uint256 inputConsumed_;

            (tx_.inputs[i], inputConsumed_) = parseTransactionInput(data_, position_);

            position_ += inputConsumed_;
        }

        uint256 outputCount_;
        (outputCount_, lenSize_) = parseCuint(data_, position_);

        position_ += lenSize_;
        tx_.outputs = new TransactionOutput[](outputCount_);

        for (uint256 i = 0; i < outputCount_; ++i) {
            uint256 outputConsumed_;

            (tx_.outputs[i], outputConsumed_) = parseTransactionOutput(data_, position_);

            position_ += outputConsumed_;
        }

        if (tx_.hasWitness) {
            for (uint256 i = 0; i < inputCount_; ++i) {
                uint256 witnessCount_;

                (witnessCount_, lenSize_) = parseCuint(data_, position_);

                position_ += lenSize_;
                tx_.inputs[i].witnesses = new bytes[](witnessCount_);

                for (uint256 j = 0; j < witnessCount_; ++j) {
                    uint256 witnessLen_;

                    (witnessLen_, lenSize_) = parseCuint(data_, position_);

                    position_ += lenSize_;

                    _checkForBufferOverflow(position_ + witnessLen_, data_.length);

                    tx_.inputs[i].witnesses[j] = data_.slice(position_, position_ + witnessLen_);

                    position_ += witnessLen_;
                }
            }
        }

        _checkForBufferOverflow(position_ + 4, data_.length);

        tx_.locktime = EndianConverter.leBytes1ToUint32(
            data_[position_],
            data_[position_ + 1],
            data_[position_ + 2],
            data_[position_ + 3]
        );

        position_ += 4;

        consumed_ = position_;
    }

    /**
     * @notice Parse a transaction input from raw bytes
     * @param data_ The raw transaction data
     * @param offset_ The starting position
     * @return input_ The parsed transaction input
     * @return consumed_ Number of bytes consumed
     */
    function parseTransactionInput(
        bytes calldata data_,
        uint256 offset_
    ) internal pure returns (TransactionInput memory input_, uint256 consumed_) {
        uint256 position_ = offset_;

        _checkForBufferOverflow(position_ + 32, data_.length);

        // Converting to big-endian format
        input_.previousHash = (bytes32(data_.slice(position_, position_ + 32))).reverseBytes();

        position_ += 32;

        _checkForBufferOverflow(position_ + 4, data_.length);

        input_.previousIndex = EndianConverter.leBytes1ToUint32(
            data_[position_],
            data_[position_ + 1],
            data_[position_ + 2],
            data_[position_ + 3]
        );

        position_ += 4;

        uint256 scriptLen_;
        uint256 lenSize_;

        (scriptLen_, lenSize_) = parseCuint(data_, position_);

        position_ += lenSize_;

        _checkForBufferOverflow(position_ + scriptLen_, data_.length);

        input_.script = data_.slice(position_, position_ + scriptLen_);

        position_ += scriptLen_;

        _checkForBufferOverflow(position_ + 4, data_.length);

        input_.sequence = EndianConverter.leBytes1ToUint32(
            data_[position_],
            data_[position_ + 1],
            data_[position_ + 2],
            data_[position_ + 3]
        );

        position_ += 4;

        consumed_ = position_ - offset_;
    }

    /**
     * @notice Parse a transaction output from raw bytes
     * @param data_ The raw transaction data
     * @param offset_ The starting position
     * @return output_ The parsed transaction output
     * @return consumed_ Number of bytes consumed
     */
    function parseTransactionOutput(
        bytes calldata data_,
        uint256 offset_
    ) internal pure returns (TransactionOutput memory output_, uint256 consumed_) {
        uint256 position_ = offset_;

        _checkForBufferOverflow(position_ + 8, data_.length);

        output_.value = int64(
            uint64((bytes32(data_.slice(position_, position_ + 8))).leBytes32ToUint256())
        );

        position_ += 8;

        uint256 scriptLen_;
        uint256 lenSize_;

        (scriptLen_, lenSize_) = parseCuint(data_, position_);

        position_ += lenSize_;

        _checkForBufferOverflow(position_ + scriptLen_, data_.length);

        output_.script = data_.slice(position_, position_ + scriptLen_);

        position_ += scriptLen_;

        consumed_ = position_ - offset_;
    }

    /**
     * @notice Parse a compact unsigned integer (Bitcoin's variable length encoding)
     * @param data_ The byte array containing the cuint
     * @param offset_ The starting position
     * @return value_ The parsed integer value
     * @return consumed_ Number of bytes consumed
     */
    function parseCuint(
        bytes calldata data_,
        uint256 offset_
    ) internal pure returns (uint256 value_, uint256 consumed_) {
        _checkForBufferOverflow(offset_ + 1, data_.length);

        uint8 firstByte_ = uint8(data_[offset_]);

        if (firstByte_ < 0xfd) {
            return (uint256(firstByte_), 1);
        }

        if (firstByte_ == 0xfd) {
            _checkForBufferOverflow(offset_ + 3, data_.length);

            value_ =
                uint256(uint8(data_[offset_ + 1])) |
                (uint256(uint8(data_[offset_ + 2])) << 8);

            return (value_, 3);
        }

        if (firstByte_ == 0xfe) {
            _checkForBufferOverflow(offset_ + 5, data_.length);

            value_ = uint256(
                EndianConverter.leBytes1ToUint32(
                    data_[offset_ + 1],
                    data_[offset_ + 2],
                    data_[offset_ + 3],
                    data_[offset_ + 4]
                )
            );

            return (value_, 5);
        }

        _checkForBufferOverflow(offset_ + 9, data_.length);

        value_ = bytes32(data_.slice(offset_ + 1, offset_ + 9)).leBytes32ToUint256();

        return (value_, 9);
    }

    /**
     * @notice Format an integer as a compact unsigned integer
     * @param value_ The integer to encode
     * @return The encoded bytes
     */
    function formatCuint(uint256 value_) internal pure returns (bytes memory) {
        if (value_ < 0xfd) {
            return abi.encodePacked(uint8(value_));
        }

        if (value_ <= 0xffff) {
            return abi.encodePacked(uint8(0xfd), uint16(value_));
        }

        if (value_ <= 0xffffffff) {
            return abi.encodePacked(uint8(0xfe), uint32(value_));
        }

        return abi.encodePacked(uint8(0xff), uint64(value_));
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

        bytes memory result_ = EndianConverter.uint32ToBytesLE(uint32(tx_.version));

        if (includeWitness_) {
            result_ = abi.encodePacked(result_, uint8(0), uint8(1));
        }

        uint256 txInputsLength_ = tx_.inputs.length;
        result_ = abi.encodePacked(result_, formatCuint(txInputsLength_));

        for (uint256 i = 0; i < txInputsLength_; ++i) {
            result_ = abi.encodePacked(result_, formatTransactionInput(tx_.inputs[i]));
        }

        uint256 txOutputsLength_ = tx_.outputs.length;
        result_ = abi.encodePacked(result_, formatCuint(txOutputsLength_));

        for (uint256 i = 0; i < txOutputsLength_; ++i) {
            result_ = abi.encodePacked(result_, formatTransactionOutput(tx_.outputs[i]));
        }

        if (includeWitness_) {
            for (uint256 i = 0; i < txInputsLength_; ++i) {
                uint256 witnessesLength_ = tx_.inputs[i].witnesses.length;
                result_ = abi.encodePacked(result_, formatCuint(witnessesLength_));

                for (uint256 j = 0; j < witnessesLength_; ++j) {
                    result_ = abi.encodePacked(
                        result_,
                        formatCuint(tx_.inputs[i].witnesses[j].length),
                        tx_.inputs[i].witnesses[j]
                    );
                }
            }
        }

        result_ = abi.encodePacked(result_, tx_.locktime);

        return result_;
    }

    /**
     * @notice Format a transaction input into raw bytes
     * @param input_ The transaction input to format
     * @return The formatted bytes
     */
    function formatTransactionInput(
        TransactionInput calldata input_
    ) internal pure returns (bytes memory) {
        bytes memory prevHash_ = (input_.previousHash).reverseBytes32ToBytes();

        bytes memory previousIndex_ = (input_.previousIndex).uint32ToBytesLE();
        bytes memory sequence_ = (input_.sequence).uint32ToBytesLE();

        return
            abi.encodePacked(
                prevHash_,
                previousIndex_,
                formatCuint(input_.script.length),
                input_.script,
                sequence_
            );
    }

    /**
     * @notice Format a transaction output into raw bytes
     * @param output_ The transaction output to format
     * @return The formatted bytes
     */
    function formatTransactionOutput(
        TransactionOutput calldata output_
    ) internal pure returns (bytes memory) {
        bytes memory value_ = (output_.value).int64ToBytesLE();

        return abi.encodePacked(value_, formatCuint(output_.script.length), output_.script);
    }

    /**
     * @notice Calculate transaction ID (hash without witness data)
     * @param tx_ The transaction
     * @return The transaction ID
     */
    function calculateTxId(Transaction calldata tx_) internal pure returns (bytes32) {
        bytes memory serialized_ = formatTransaction(tx_, false);

        return _doubleSHA256(serialized_);
    }

    /**
     * @notice Calculate witness transaction ID (hash with witness data)
     * @param tx_ The transaction
     * @return The witness transaction ID
     */
    function calculateWTxId(Transaction calldata tx_) internal pure returns (bytes32) {
        bytes memory serialized_ = formatTransaction(tx_, true);

        return _doubleSHA256(serialized_);
    }

    function _checkForBufferOverflow(uint256 positionToCheck_, uint256 dataLength_) private pure {
        if (positionToCheck_ > dataLength_) {
            revert BufferOverflow();
        }
    }

    function _doubleSHA256(bytes memory data_) private pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}
