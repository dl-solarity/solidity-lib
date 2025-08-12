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
     * @notice Possible directions for hashing:
     * Left: computed hash is on the left, sibling hash is on the right.
     * Right: computed hash is on the right, sibling hash is on the left.
     * Self: node has no sibling and is hashed with itself
     * */
    enum HashDirection {
        Left,
        Right,
        Self
    }

    /**
     * @notice Emitted when the proof and directions array are of different length.
     * This error ensures that only correctly sized proofs are processed
     */
    error InvalidLengths();

    /**
     * @notice Emitted when the concateneted hashes of the Merkle tree is a valid Bitcoin transaction.
     * This error ensures that insertion attack is not possible
     */
    error InvalidMerkleNode();

    /**
     * @notice Returns true if `leaf_` can be proven to be part of a Merkle tree
     * defined by `root_`. Uses double SHA-256 hashing
     * @param proof_ The array of sibling hashes from the leaf to the root
     * @param directions_ The array of uint8, indicating hashing order for each pair
     * @param leaf_ Element that need to be proven included in a tree
     * @param root_ Merkle root in little-endian format
     */
    function verify(
        bytes32[] memory proof_,
        bytes32 root_,
        bytes32 leaf_,
        HashDirection[] memory directions_
    ) internal pure returns (bool) {
        if (directions_.length != proof_.length) revert InvalidLengths();

        return processProof(proof_, leaf_, directions_) == root_;
    }

    /**
     * @notice Returns the rebuilt hash obtained by traversing the Merkle tree
     * from `leaf_` using `proof_`. A `proof_` is valid if and only if the rebuilt
     * hash matches the given tree root. The pre-images are hashed in the order
     * specified by the `directions_` elements. Uses double SHA-256 hashing
     * @param proof_ The array of sibling hashes from the leaf to the root
     * @param directions_ The array of uint8, indicating hashing order for each pair
     * @param leaf_ The leaf of the Merkle tree
     */
    function processProof(
        bytes32[] memory proof_,
        bytes32 leaf_,
        HashDirection[] memory directions_
    ) internal pure returns (bytes32) {
        bytes32 computedHash_ = leaf_;
        uint256 proofLength_ = proof_.length;
        bytes memory pair_;

        for (uint256 i = 0; i < proofLength_; ++i) {
            if (directions_[i] == HashDirection.Left) {
                pair_ = abi.encodePacked(computedHash_, proof_[i]);
            } else if (directions_[i] == HashDirection.Right) {
                pair_ = abi.encodePacked(proof_[i], computedHash_);
            } else {
                pair_ = abi.encodePacked(computedHash_, computedHash_);
            }

            if (pair_.isBitcoinTransaction()) revert InvalidMerkleNode();

            computedHash_ = _doubleSHA256(pair_);
        }

        return computedHash_;
    }

    function _doubleSHA256(bytes memory data_) private pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}
