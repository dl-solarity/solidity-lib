// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAccountRecovery} from "../interfaces/account-recovery/IAccountRecovery.sol";
import {IRecoveryProvider} from "../interfaces/account-recovery/IRecoveryProvider.sol";

/**
 * @notice The Account Recovery module
 *
 * Contract module which provides a basic account recovery mechanism.
 *
 * The Account Recovery module allows to add recovery providers to the account.
 * The recovery providers are used to recover the account ownership.
 */
abstract contract AAccountRecovery is IAccountRecovery {
    struct AAccountRecoveryStorage {
        mapping(address => bool) recoveryProviders;
    }

    // bytes32(uint256(keccak256("solarity.contract.AAccountRecovery")) - 1)
    bytes32 private constant A_ACCOUNT_RECOVERY_STORAGE =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    error ZeroAddress();
    error ProviderAlreadyAdded(address provider);
    error ProviderNotRegistered(address provider);

    function recoveryProviderAdded(address provider_) public view returns (bool) {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        return $.recoveryProviders[provider_];
    }

    function _addRecoveryProvider(address provider_, bytes memory recoveryData_) internal {
        if (provider_ == address(0)) revert ZeroAddress();

        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if ($.recoveryProviders[provider_]) revert ProviderAlreadyAdded(provider_);

        IRecoveryProvider(provider_).subscribe(recoveryData_);

        $.recoveryProviders[provider_] = true;

        emit RecoveryProviderAdded(provider_);
    }

    function _removeRecoveryProvider(address provider_) internal {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders[provider_]) revert ProviderNotRegistered(provider_);

        IRecoveryProvider(provider_).unsubscribe();

        delete $.recoveryProviders[provider_];

        emit RecoveryProviderRemoved(provider_);
    }

    function _validateRecovery(
        address newOwner_,
        address provider_,
        bytes memory proof_
    ) internal {
        if (newOwner_ == address(0)) revert ZeroAddress();

        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders[provider_]) revert ProviderNotRegistered(provider_);

        IRecoveryProvider(provider_).recover(newOwner_, proof_);
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getAAccountRecoveryStorage()
        private
        pure
        returns (AAccountRecoveryStorage storage $)
    {
        assembly {
            $.slot := A_ACCOUNT_RECOVERY_STORAGE
        }
    }
}
