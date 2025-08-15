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
     * @param recoveryData_ a recovery commitment (hash/ZKP public output) to be used
     * in the `recover` function to check a recovery proof validity.
     */
    function subscribe(bytes memory recoveryData_) external payable;

    /**
     * @notice A function that revokes a smart account subscription.
     */
    function unsubscribe() external payable;

    /**
     * @notice A function that checks if a recovery of a smart account (msg.sender)
     * to the `newOwner` is possible.
     * SHOULD use `msg.sender`'s `recoveryData` to check the `proof` validity.
     *
     * @param object_ the new object (may be different to subject) to recover the `msg.sender` access to.
     * @param proof_ the recovery proof.
     */
    function recover(bytes memory object_, bytes memory proof_) external;

    /**
     * @notice A function to get a recovery data (commitment) of an account.
     *
     * @param account_ the account to get the recovery data of.
     * @return the associated recovery data.
     */
    function getRecoveryData(address account_) external view returns (bytes memory);
}
