// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access-control/MerkleWhitelisted.sol";

contract MerkleWhitelistedMock is MerkleWhitelisted {
    function onlyWhitelistedMethod(
        bytes calldata data_,
        bytes32[] calldata merkleProof_
    ) external onlyWhitelisted(data_, merkleProof_) {}

    function onlyWhitelistedUserMethod(
        bytes32[] calldata merkleProof_
    ) external onlyWhitelistedUser(msg.sender, merkleProof_) {}

    function setMerkleRoot(bytes32 merkleRoot_) external {
        _setMerkleRoot(merkleRoot_);
    }
}
