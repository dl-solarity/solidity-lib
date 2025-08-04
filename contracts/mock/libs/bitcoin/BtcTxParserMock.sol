// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {BtcTxParser} from "../../../libs/bitcoin/BtcTxParser.sol";

contract BtcTxParserMock {
    using BtcTxParser for *;

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

    function formatTransactionInput(
        BtcTxParser.TransactionInput calldata input_
    ) external pure returns (bytes memory) {
        return input_.formatTransactionInput();
    }

    function formatTransactionOutput(
        BtcTxParser.TransactionOutput calldata output_
    ) external pure returns (bytes memory) {
        return output_.formatTransactionOutput();
    }
}
