// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Account Recovery module
 *
 * Defines a common recovery provider interface.
 *
 * For more information please refer to [EIP-7947](https://eips.ethereum.org/EIPS/eip-7947).
 */
interface IRecoveryProvider {
    event AccountSubscribed(address indexed account);
    event AccountUnsubscribed(address indexed account);

    /**
     * @notice A function that "subscribes" a smart account (msg.sender) to a recovery provider.
     * SHOULD process and assign the `recoveryData` to the `msg.sender`.
     *
     * @param recoveryData a recovery commitment (hash/ZKP public output) to be used
     * in the `recover` function to check a recovery proof validity.
     */
    function subscribe(bytes memory recoveryData) external;

    /**
     * @notice A function that revokes a smart account subscription.
     */
    function unsubscribe() external;

    /**
     * @notice A function that checks if a recovery of a smart account (msg.sender)
     * to the `newOwner` is possible.
     * SHOULD use `msg.sender`'s `recoveryData` to check the `proof` validity.
     *
     * @param newOwner the new owner to recover the `msg.sender` ownership to.
     * @param proof the recovery proof.
     */
    function recover(address newOwner, bytes memory proof) external;

    /**
     * @notice A function to get a recovery data (commitment) of an account.
     *
     * @param account the account to get the recovery data of.
     * @return the associated recovery data.
     */
    function getRecoveryData(address account) external view returns (bytes memory);
}
