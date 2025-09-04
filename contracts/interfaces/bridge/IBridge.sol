// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Bridge module
 */
interface IBridge {
    error InvalidSigner(address signer);
    error InvalidSigners();
    error DuplicateSigner(address signer);
    error ThresholdNotMet(uint256 signers);
    error ThresholdIsZero();
    error NonceUsed(bytes32 nonce);

    function deposit(uint256 assetType_, bytes calldata depositDetails_) external payable;

    function withdraw(
        uint256 assetType_,
        bytes calldata withdrawDetails_,
        bytes calldata proof_
    ) external;
}
