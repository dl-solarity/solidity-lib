// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {TxMerkleProof} from "../../../libs/bitcoin/TxMerkleProof.sol";

contract TxMerkleProofMock {
    function verify(
        bytes32[] calldata merkleProof_,
        TxMerkleProof.HashDirection[] calldata directions_,
        bytes32 reversedRoot_,
        bytes32 txid_
    ) external pure returns (bool) {
        return TxMerkleProof.verify(merkleProof_, directions_, reversedRoot_, txid_);
    }
}
