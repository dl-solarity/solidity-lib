// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Account Recovery module
 *
 * For more information please refer to [EIP-7947](https://eips.ethereum.org/EIPS/eip-7947).
 */
interface IAccountRecovery {
    event OwnershipRecovered(address indexed oldOwner, address indexed newOwner);
    event RecoveryProviderAdded(address indexed provider);
    event RecoveryProviderRemoved(address indexed provider);

    /**
     * @notice The function to add a new recovery provider
     * @param provider_ the address of a recovery provider to add
     * @param recoveryData_ custom data (commitment) for the recovery provider
     */
    function addRecoveryProvider(address provider_, bytes memory recoveryData_) external;

    /**
     * @notice The function to remove an existing recovery provider
     * @param provider_ the address of a previously added recovery provider to remove
     */
    function removeRecoveryProvider(address provider_) external;

    /**
     * @notice The function to recover ownership of a smart account
     * @param newOwner_ the address of a new owner
     * @param provider_ the address of a recovery provider
     * @param proof_ an encoded proof of recovery
     * @return true if recovery is successful, false (or revert) otherwise
     */
    function recoverOwnership(
        address newOwner_,
        address provider_,
        bytes memory proof_
    ) external returns (bool);

    /**
     * @notice The function to check if a provider has been previously added
     * @param provider_ the provider to check
     * @return true if the provider exists in the account, false otherwise
     */
    function recoveryProviderAdded(address provider_) external view returns (bool);

    /**
     * @notice The function to get the list of current recovery providers.
     * @return the list of current recovery providers
     */
    function getRecoveryProviders() external view returns (address[] memory);
}
