// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAccountRecovery} from "../interfaces/account-abstraction/IAccountRecovery.sol";
import {IRecoveryProvider} from "../interfaces/account-abstraction/IRecoveryProvider.sol";

/**
 * @notice The Account Recovery module
 *
 * Contract module which provides a basic account recovery mechanism as specified in EIP-7947.
 * You may use this module as a base contract for your own account recovery mechanism.
 *
 * The Account Recovery module allows to add recovery providers to the account.
 * The recovery providers are used to recover the account access.
 *
 * For more information please refer to [EIP-7947](https://eips.ethereum.org/EIPS/eip-7947).
 */
abstract contract AAccountRecovery is IAccountRecovery {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct AAccountRecoveryStorage {
        EnumerableSet.AddressSet recoveryProviders;
    }

    // bytes32(uint256(keccak256("solarity.contract.AAccountRecovery")) - 1)
    bytes32 private constant A_ACCOUNT_RECOVERY_STORAGE =
        0x828c412330620ced6ea61864e26a29daa3e4c6ed06ccbde7b849e007ed9dd85a;

    error ZeroAddress();
    error ProviderAlreadyAdded(address provider);
    error ProviderNotRegistered(address provider);

    /**
     * @inheritdoc IAccountRecovery
     */
    function addRecoveryProvider(
        address provider_,
        bytes memory recoveryData_
    ) external payable virtual;

    /**
     * @inheritdoc IAccountRecovery
     */
    function removeRecoveryProvider(address provider_) external payable virtual;

    /**
     * @inheritdoc IAccountRecovery
     */
    function recoverAccess(
        bytes memory subject_,
        address provider_,
        bytes memory proof_
    ) external virtual returns (bool);

    /**
     * @inheritdoc IAccountRecovery
     */
    function recoveryProviderAdded(address provider_) public view virtual returns (bool) {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        return $.recoveryProviders.contains(provider_);
    }

    /**
     * @notice A function to get the list of all the recovery providers added to the account
     * @return the list of recovery providers
     */
    function getRecoveryProviders() public view virtual returns (address[] memory) {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        return $.recoveryProviders.values();
    }

    /**
     * @notice Should be called in the `addRecoveryProvider` function
     */
    function _addRecoveryProvider(address provider_, bytes memory recoveryData_) internal virtual {
        if (provider_ == address(0)) revert ZeroAddress();

        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.add(provider_)) revert ProviderAlreadyAdded(provider_);

        IRecoveryProvider(provider_).subscribe(recoveryData_);

        emit RecoveryProviderAdded(provider_);
    }

    /**
     * @notice Should be called in the `removeRecoveryProvider` function
     */
    function _removeRecoveryProvider(address provider_) internal virtual {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.remove(provider_)) revert ProviderNotRegistered(provider_);

        IRecoveryProvider(provider_).unsubscribe();

        emit RecoveryProviderRemoved(provider_);
    }

    /**
     * @notice Should be called in the `recoverAccess` function before updating the account access
     */
    function _validateRecovery(
        bytes memory object_,
        address provider_,
        bytes memory proof_
    ) internal virtual {
        AAccountRecoveryStorage storage $ = _getAAccountRecoveryStorage();

        if (!$.recoveryProviders.contains(provider_)) revert ProviderNotRegistered(provider_);

        IRecoveryProvider(provider_).recover(object_, proof_);
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
