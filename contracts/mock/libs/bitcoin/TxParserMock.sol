// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {TxParser} from "../../../libs/bitcoin/TxParser.sol";

contract TxParserMock {
    using TxParser for *;

    function calculateTxId(bytes calldata data_) external pure returns (bytes32) {
        return data_.calculateTxId();
    }

    function calculateWTxId(bytes calldata data_) external pure returns (bytes32) {
        return data_.calculateWTxId();
    }

    function parseBTCTransaction(
        bytes calldata txBytes_
    ) external pure returns (TxParser.Transaction memory tx_) {
        uint256 consumed_;
        (tx_, consumed_) = txBytes_.parseTransaction();

        return tx_;
    }

    function isTransaction(bytes memory rawTx_) external pure returns (bool) {
        return rawTx_.isTransaction();
    }

    function parseCuint(
        bytes calldata data_
    ) external pure returns (uint64 value_, uint8 consumed_) {
        return data_.parseCuint();
    }

    function formatCuint(uint64 value_) external pure returns (bytes memory) {
        return value_.formatCuint();
    }

    function formatTransaction(
        TxParser.Transaction calldata tx_,
        bool withWitness_
    ) external pure returns (bytes memory) {
        return tx_.formatTransaction(withWitness_);
    }
}
