// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {BtcTxParser} from "../../../libs/bitcoin/BtcTxParser.sol";

contract BtcTxParserMock {
    using BtcTxParser for *;

    function calculateTxId(bytes calldata data_) external pure returns (bytes32) {
        return data_.calculateTxId();
    }

    function calculateWTxId(bytes calldata data_) external pure returns (bytes32) {
        return data_.calculateWTxId();
    }

    function parseBTCTransaction(
        bytes calldata txBytes_
    ) external pure returns (BtcTxParser.Transaction memory tx_) {
        uint256 consumed_;
        (tx_, consumed_) = txBytes_.parseTransaction();

        return tx_;
    }

    function parseCuint(
        bytes calldata data_,
        uint256 offset_
    ) external pure returns (uint256 value_, uint256 consumed_) {
        return data_.parseCuint(offset_);
    }

    function formatCuint(uint256 value_) external pure returns (bytes memory) {
        return value_.formatCuint();
    }

    function formatTransaction(
        BtcTxParser.Transaction calldata tx_,
        bool withWitness_
    ) external pure returns (bytes memory) {
        return tx_.formatTransaction(withWitness_);
    }
}
