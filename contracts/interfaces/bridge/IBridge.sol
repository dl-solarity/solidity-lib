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

    /**
     * @notice A function to dispatch assets or messages to another chain.
     * @param assetType_ the asset type identifier linked to a handler.
     * @param dispatchDetails_ encoded handler-specific dispatch data.
     */
    function dispatch(uint256 assetType_, bytes calldata dispatchDetails_) external payable;

    /**
     * @notice A function to redeem an incoming cross-chain operation.
     * @dev Requires enough valid signer approvals to pass threshold checks.
     * @param assetType_ the asset type identifier linked to a handler.
     * @param redeemDetails_ encoded handler-specific redeem data.
     * @param proof_ a proof of signer approvals authorizing the redemption.
     */
    function redeem(
        uint256 assetType_,
        bytes calldata redeemDetails_,
        bytes calldata proof_
    ) external;
}
