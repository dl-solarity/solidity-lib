// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
        require(
            isWhitelisted(_convertUserToLeaf(user_), merkleProof_),
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

    function isWhitelistedUser(
        address user_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        return merkleProof_.verifyCalldata(_merkleRoot, _convertUserToLeaf(user_));
    }

    function getMerkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    function _setMerkleRoot(bytes32 merkleRoot_) internal {
        _merkleRoot = merkleRoot_;
    }

    function _convertUserToLeaf(address user_) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(user_));
    }
}
