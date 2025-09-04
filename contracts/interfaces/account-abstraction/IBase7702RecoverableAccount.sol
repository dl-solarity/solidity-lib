// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IBatchExecutor} from "./erc-7821/IBatchExecutor.sol";
import {IAccountRecovery} from "./IAccountRecovery.sol";

interface IBase7702RecoverableAccount is IBatchExecutor, IAccountRecovery {
    error NotSelfCalled();
    error NotSelfOrTrustedExecutor(address account);
    error TrustedExecutorAlreadyAdded(address trustedExecutor);
    error TrustedExecutorNotRegistered(address trustedExecutor);

    event TrustedExecutorAdded(address indexed newTrustedExecutor);
    event TrustedExecutorRemoved(address indexed trustedExecutor);

    function updateTrustedExecutor(address trustedExecutor_, bool isAdding_) external;

    function getTrustedExecutors() external view returns (address[] memory);
}
