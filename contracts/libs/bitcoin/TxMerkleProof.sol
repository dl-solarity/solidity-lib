// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {TxParser} from "./TxParser.sol";

/**
 * @notice A library for verifying transaction inclusion in Bitcoin block.
 * Provides functions for processing and verifying Merkle tree proofs
 */
library TxMerkleProof {
    using TxParser for bytes;

    /**
     * @notice Emitted when the concateneted hashes of the Merkle tree is a valid Bitcoin transaction.
     * This error ensures that insertion attack is not possible
     */
    error InvalidMerkleNode();

    /**
     * @notice Returns true if `leaf_` can be proven to be part of a Merkle tree
     * defined by `root_`. Uses double SHA-256 hashing
     * @param proof_ The array of sibling hashes from the leaf to the root
     * @param root_ Merkle root in little-endian format
     * @param leaf_ Element that need to be proven included in a tree
     * @param txIndex_ The transaction index in the block, indicating hashing order for each pair
     */
    function verify(
        bytes32[] memory proof_,
        bytes32 root_,
        bytes32 leaf_,
        uint256 txIndex_
    ) internal pure returns (bool) {
        return processProof(proof_, leaf_, txIndex_) == root_;
    }

    /**
     * @notice Returns the rebuilt hash obtained by traversing the Merkle tree
     * from `leaf_` using `proof_`. A `proof_` is valid if and only if the rebuilt
     * hash matches the given tree root. The pre-images are hashed in the order
     * calculated by the `txIndex_` position. Uses double SHA-256 hashing
     * @dev Every pair of nodes is checked for being a valid transaction
     * to mitigate insertion attack
     * @param proof_ The array of sibling hashes from the leaf to the root
     * @param leaf_ The leaf of the Merkle tree
     * @param txIndex_ The transaction index in the block, indicating hashing order for each pair
     */
    function processProof(
        bytes32[] memory proof_,
        bytes32 leaf_,
        uint256 txIndex_
    ) internal pure returns (bytes32) {
        bytes32 computedHash_ = leaf_;
        uint256 proofLength_ = proof_.length;
        bytes memory pair_;

        for (uint256 i = 0; i < proofLength_; ++i) {
            pair_ = txIndex_ & 1 == 0
                ? abi.encodePacked(computedHash_, proof_[i])
                : abi.encodePacked(proof_[i], computedHash_);

            if (pair_.isTransaction()) revert InvalidMerkleNode();

            computedHash_ = _doubleSHA256(pair_);
            txIndex_ >>= 1;
        }

        return computedHash_;
    }

    function _doubleSHA256(bytes memory data_) private pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}
