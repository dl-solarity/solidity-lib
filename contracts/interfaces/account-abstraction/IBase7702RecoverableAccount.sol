// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBatchExecutor} from "./erc-7821/IBatchExecutor.sol";
import {IAccountRecovery} from "./IAccountRecovery.sol";

/**
 * @notice The EIP-7702 Recoverable Account module
 */
interface IBase7702RecoverableAccount is IBatchExecutor, IAccountRecovery {
    error NotSelfCalled();
    error NotSelfOrTrustedExecutor(address account);
    error TrustedExecutorAlreadyAdded(address trustedExecutor);
    error TrustedExecutorNotRegistered(address trustedExecutor);

    event TrustedExecutorAdded(address indexed newTrustedExecutor);
    event TrustedExecutorRemoved(address indexed trustedExecutor);

    /**
     * @notice A function to add a new trusted executor.
     * @param newTrustedExecutor_ The address of the executor to add.
     */
    function addTrustedExecutor(address newTrustedExecutor_) external;

    /**
     * @notice A function to remove an existing trusted executor.
     * @param trustedExecutor_ The address of the executor to remove.
     */
    function removeTrustedExecutor(address trustedExecutor_) external;

    /**
     * @notice A function to retrieve the list of all trusted executors.
     * @return An array of trusted executor addresses.
     */
    function getTrustedExecutors() external view returns (address[] memory);

    /**
     * @notice A function to check whether a given address is a registered trusted executor.
     * @param account_ The address of an executor to check.
     * @return `true` if the address is a trusted executor, `false` otherwise.
     */
    function isTrustedExecutor(address account_) external view returns (bool);
}
