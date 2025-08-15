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
    event AccessRecovered(bytes subject);
    event RecoveryProviderAdded(address indexed provider);
    event RecoveryProviderRemoved(address indexed provider);

    /**
     * @notice A function to add a new recovery provider.
     * SHOULD be access controlled.
     *
     * @param provider_ the address of a recovery provider (ZKP verifier) to add.
     * @param recoveryData_ custom data (commitment) for the recovery provider.
     */
    function addRecoveryProvider(address provider_, bytes memory recoveryData_) external payable;

    /**
     * @notice A function to remove an existing recovery provider.
     * SHOULD be access controlled.
     *
     * @param provider_ the address of a previously added recovery provider to remove.
     */
    function removeRecoveryProvider(address provider_) external payable;

    /**
     * @notice A non-view function to recover access of a smart account.
     * @param subject_ the recovery subject (encoded owner address, access control role, etc).
     * @param provider_ the address of a recovery provider.
     * @param proof_ an encoded proof of recovery (ZKP/ZKAI, signature, etc).
     * @return `true` if recovery is successful, `false` (or revert) otherwise.
     */
    function recoverAccess(
        bytes memory subject_,
        address provider_,
        bytes memory proof_
    ) external returns (bool);

    /**
     * @notice A view function to check if a provider has been previously added.
     * @param provider the provider to check.
     * @return true if the provider exists in the account, false otherwise.
     */
    function recoveryProviderAdded(address provider) external view returns (bool);
}
