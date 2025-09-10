// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Basic ERC-4337 Account module
 */
interface IAccount {
    struct PackedUserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        bytes32 accountGasLimits;
        uint256 preVerificationGas;
        bytes32 gasFees;
        bytes paymasterAndData;
        bytes signature;
    }

    error NotAnEntryPoint(address caller);

    /**
     * @notice A function to validate a `PackedUserOperation` for the account.
     * @dev This function is called from the `EntryPoint` while executing the user operation.
     *      Must be implemented by accounts to verify signatures and pay required funds.
     * @param userOp_ The user operation being validated.
     * @param userOpHash_ The user operation hash used for signature validation.
     * @param missingAccountFunds_ Amount that the account must fund to the `EntryPoint`.
     * @return validationData_ The result of the signature validation.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp_,
        bytes32 userOpHash_,
        uint256 missingAccountFunds_
    ) external returns (uint256 validationData_);

    /**
     * @notice A function to retrieve the address of the `EntryPoint` this account is bound to.
     * @return The `EntryPoint` contract address.
     */
    function entryPoint() external view returns (address);
}
