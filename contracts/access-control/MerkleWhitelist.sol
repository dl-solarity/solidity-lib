// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleWhitelist {
    using MerkleProof for bytes32[];

    bytes32 internal _merkleRoot;

    modifier onlyWhitelisted(bytes32[] calldata merkleProof_) {
        require(isWhitelisted(msg.sender, merkleProof_), "MerkleWhitelist: not whitelisted");
        _;
    }

    modifier onlyWhitelistedUser(address user_, bytes32[] calldata merkleProof_) {
        require(isWhitelisted(user_, merkleProof_), "MerkleWhitelist: not whitelisted");
        _;
    }

    function setMerkleRoot(bytes32 merkleRoot_) internal {
        _merkleRoot = merkleRoot_;
    }

    function isWhitelisted(
        address user_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        return merkleProof_.verifyCalldata(_merkleRoot, keccak256(abi.encodePacked(user_)));
    }
}
