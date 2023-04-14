// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MerkleWhitelisted} from "../../access-control/MerkleWhitelisted.sol";

contract MerkleWhitelistedMock is MerkleWhitelisted {
    event WhitelistedUser();
    event WhitelistedData();

    function onlyWhitelistedMethod(
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external onlyWhitelisted(_encode(amount_), merkleProof_) {
        emit WhitelistedData();
    }

    function onlyWhitelistedUserMethod(
        bytes32[] calldata merkleProof_
    ) external onlyWhitelistedUser(msg.sender, merkleProof_) {
        emit WhitelistedUser();
    }

    function setMerkleRoot(bytes32 merkleRoot_) external {
        _setMerkleRoot(merkleRoot_);
    }

    function _encode(uint256 amount_) private view returns (bytes memory) {
        return abi.encodePacked(amount_, msg.sender);
    }
}
