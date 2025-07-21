// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Account Recovery module
 *
 * Defines a common account recovery interface for smart accounts to implement.
 *
 * For more information please refer to [EIP-7947](https://eips.ethereum.org/EIPS/eip-7947).
 */
interface IAccountRecovery {
    event OwnershipRecovered(address indexed oldOwner, address indexed newOwner);
    event RecoveryProviderAdded(address indexed provider);
    event RecoveryProviderRemoved(address indexed provider);

    /**
     * @notice A function to add a new recovery provider.
     * SHOULD be access controlled.
     *
     * @param provider the address of a recovery provider (ZKP verifier) to add.
     * @param recoveryData custom data (commitment) for the recovery provider.
     */
    function addRecoveryProvider(address provider, bytes memory recoveryData) external;

    /**
     * @notice A function to remove an existing recovery provider.
     * SHOULD be access controlled.
     *
     * @param provider the address of a previously added recovery provider to remove.
     */
    function removeRecoveryProvider(address provider) external;

    /**
     * @notice A non-view function to recover ownership of a smart account.
     * @param newOwner the address of a new owner.
     * @param provider the address of a recovery provider.
     * @param proof an encoded proof of recovery (ZKP/ZKAI, signature, etc).
     * @return `true` if recovery is successful, `false` (or revert) otherwise.
     */
    function recoverOwnership(
        address newOwner,
        address provider,
        bytes memory proof
    ) external returns (bool);

    /**
     * @notice A view function to check if a provider has been previously added.
     * @param provider the provider to check.
     * @return true if the provider exists in the account, false otherwise.
     */
    function recoveryProviderAdded(address provider) external view returns (bool);
}
