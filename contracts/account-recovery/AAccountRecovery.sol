// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
    using EnumerableSet for EnumerableSet.AddressSet;

    struct AAccountRecoveryStorage {
        EnumerableSet.AddressSet recoveryProviders;
    }

    // bytes32(uint256(keccak256("solarity.contract.AAccountRecovery")) - 1)
    bytes32 private constant A_ACCOUNT_RECOVERY_STORAGE =
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

    error ZeroAddress();
    error ProviderAlreadyAdded(address provider);
    error ProviderNotRegistered(address provider);

    function recoveryProviderAdded(address provider_) public view returns (bool) {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        return $.recoveryProviders.contains(provider_);
    }

    function getRecoveryProviders() public view returns (address[] memory) {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        return $.recoveryProviders.values();
    }

    function _addRecoveryProvider(address provider_, bytes memory recoveryData_) internal {
        if (provider_ == address(0)) revert ZeroAddress();

        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.add(provider_)) revert ProviderAlreadyAdded(provider_);

        IRecoveryProvider(provider_).subscribe(recoveryData_);

        emit RecoveryProviderAdded(provider_);
    }

    function _removeRecoveryProvider(address provider_) internal {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.remove(provider_)) revert ProviderNotRegistered(provider_);

        IRecoveryProvider(provider_).unsubscribe();

        emit RecoveryProviderRemoved(provider_);
    }

    function _validateRecovery(
        address newOwner_,
        address provider_,
        bytes memory proof_
    ) internal {
        if (newOwner_ == address(0)) revert ZeroAddress();

        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.contains(provider_)) revert ProviderNotRegistered(provider_);

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
