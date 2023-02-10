// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleWhitelisted {
    using MerkleProof for bytes32[];

    bytes32 internal _merkleRoot;

    modifier onlyWhitelisted(bytes calldata data, bytes32[] calldata merkleProof_) {
        require(
            isWhitelisted(keccak256(data), merkleProof_),
            "MerkleWhitelisted: not whitelisted"
        );
        _;
    }

    modifier onlyWhitelistedUser(address user_, bytes32[] calldata merkleProof_) {
        require(
            isWhitelisted(keccak256(abi.encodePacked(user_)), merkleProof_),
            "MerkleWhitelisted: not whitelisted"
        );
        _;
    }

    function isWhitelisted(
        bytes32 leaf_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        return merkleProof_.verifyCalldata(_merkleRoot, leaf_);
    }

    function _setMerkleRoot(bytes32 merkleRoot_) internal {
        _merkleRoot = merkleRoot_;
    }
}
