// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Recovery Provider module
 */
interface IRecoveryProvider {
    event AccountSubscribed(address indexed account);
    event AccountUnsubscribed(address indexed account);

    /**
     * @notice The function to `subscribes` a smart account (msg.sender) to a recovery provider
     * @param recoveryData_ a recovery commitment to be used
     */
    function subscribe(bytes memory recoveryData_) external;

    /**
     * @notice The function to revoke a smart account subscription
     */
    function unsubscribe() external;

    /**
     * @notice The function to check if a recovery of a smart account (msg.sender)
     * to the `newOwner` is possible
     * @param newOwner_ the new owner to recover the `msg.sender` ownership to
     * @param proof_ the recovery proof
     */
    function recover(address newOwner_, bytes memory proof_) external;

    /**
     * @notice The function to get a recovery data (commitment) of an account
     * @param account_ the account to get the recovery data of
     * @return the associated recovery data
     */
    function getRecoveryData(address account_) external view returns (bytes memory);
}
