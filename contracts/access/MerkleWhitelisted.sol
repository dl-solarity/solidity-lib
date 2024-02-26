// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice The Whitelist Access Control module
 *
 * This is a simple abstract contract that implements whitelisting logic.
 *
 * The contract is based on a Merkle tree, which allows for the huge whitelists to be cheaply validated courtesy of
 * O(log(n)) tree complexity. The whitelist itself is stored in the tree leaves and only the root of the tree is saved on-chain.
 *
 * To validate the whitelist belonging, the tree leaf (the whitelist element) has to be computed and passed to the
 * "root-construction" function together with the corresponding tree branches. The function will then check the
 * roots equality. If the roots match, the element belongs to the whitelist.
 *
 * Note: the branch nodes are sorted numerically.
 */
abstract contract MerkleWhitelisted {
    using MerkleProof for bytes32[];

    bytes32 private _merkleRoot;

    modifier onlyWhitelisted(bytes memory data_, bytes32[] calldata merkleProof_) {
        require(
            isWhitelisted(keccak256(data_), merkleProof_),
            "MerkleWhitelisted: not whitelisted"
        );
        _;
    }

    modifier onlyWhitelistedUser(address user_, bytes32[] calldata merkleProof_) {
        require(isWhitelistedUser(user_, merkleProof_), "MerkleWhitelisted: not whitelisted");
        _;
    }

    /**
     * @notice The function to check if the leaf belongs to the Merkle tree
     * @param leaf_ the leaf to be checked
     * @param merkleProof_ the path from the leaf to the Merkle tree root
     * @return true if the leaf belongs to the Merkle tree, false otherwise
     */
    function isWhitelisted(
        bytes32 leaf_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        return merkleProof_.verifyCalldata(_merkleRoot, leaf_);
    }

    /**
     * @notice The function to check if the user belongs to the Merkle tree
     * @param user_ the user to be checked
     * @param merkleProof_ the path from the user to the Merkle tree root
     * @return true if the user belongs to the Merkle tree, false otherwise
     */
    function isWhitelistedUser(
        address user_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        return isWhitelisted(keccak256(abi.encodePacked(user_)), merkleProof_);
    }

    /**
     * @notice The function to get the current Merkle root
     * @return the current Merkle root or zero bytes if it has not been set
     */
    function getMerkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     * @notice The function that should be called from the child contract to set the Merkle root
     * @param merkleRoot_ the Merkle root to be set
     */
    function _setMerkleRoot(bytes32 merkleRoot_) internal {
        _merkleRoot = merkleRoot_;
    }
}
