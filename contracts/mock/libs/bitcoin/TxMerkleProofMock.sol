// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {TxMerkleProof} from "../../../libs/bitcoin/TxMerkleProof.sol";

contract TxMerkleProofMock {
    function verify(
        bytes32[] calldata merkleProof_,
        bytes32 reversedRoot_,
        bytes32 txid_,
        uint256 txIndex_
    ) external pure returns (bool) {
        return TxMerkleProof.verify(merkleProof_, reversedRoot_, txid_, txIndex_);
    }
}
