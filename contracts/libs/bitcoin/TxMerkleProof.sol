// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {BitcoinHelper} from "./BitcoinHelper.sol";

/**
 * @notice A library for verifying transaction inclusion in Bitcoin block.
 * Provides functions for processing and verifying Merkle tree proofs
 */
library TxMerkleProof {
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
     * @notice Returns true if `leaf_` can be proven to be part of a Merkle tree
     * defined by `root_`. Requires a `proof_` containing the sibling hashes along
     * the path from the leaf to the root. Each element of `directions_` indicates
     * the hashing order for each pair. Uses double SHA-256 hashing
     */
    function verify(
        bytes32[] calldata proof_,
        HashDirection[] calldata directions_,
        bytes32 leaf_,
        bytes32 root_
    ) internal pure returns (bool) {
        if (directions_.length != proof_.length) revert InvalidLengths();

        return processProof(proof_, directions_, leaf_) == root_;
    }

    /**
     * @notice Returns the rebuilt hash obtained by traversing the Merkle tree
     * from `leaf_` using `proof_`. A `proof_` is valid if and only if the rebuilt
     * hash matches the given tree root. The pre-images are hashed in the order
     * specified by the `directions_` elements. Uses double SHA-256 hashing
     */
    function processProof(
        bytes32[] calldata proof_,
        HashDirection[] calldata directions_,
        bytes32 leaf_
    ) internal pure returns (bytes32) {
        bytes32 computedHash_ = leaf_;
        uint256 proofLength_ = proof_.length;

        for (uint256 i = 0; i < proofLength_; ++i) {
            if (directions_[i] == HashDirection.Left) {
                computedHash_ = _doubleSHA256(computedHash_, proof_[i]);
            } else if (directions_[i] == HashDirection.Right) {
                computedHash_ = _doubleSHA256(proof_[i], computedHash_);
            } else {
                computedHash_ = _doubleSHA256(computedHash_, computedHash_);
            }
        }

        return computedHash_;
    }

    function _doubleSHA256(bytes32 left_, bytes32 right_) private pure returns (bytes32) {
        return BitcoinHelper.doubleSHA256(abi.encodePacked(left_, right_));
    }
}
