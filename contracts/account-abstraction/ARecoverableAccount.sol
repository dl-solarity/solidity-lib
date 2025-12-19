// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC7821} from "solady/src/accounts/ERC7821.sol";

import {AAccountRecovery} from "./AAccountRecovery.sol";
import {IAccount} from "../interfaces/account-abstraction/erc-4337/IAccount.sol";

/**
 * @notice EIP-7702/ERC-4337 Recoverable Account module
 *
 * A basic EIP-7702/ERC-4337 account implementation with ERC-7821 batching execution,
 * ERC-4337 sponsored transactions, and ERC-7947 recoverable trusted executor.
 */
abstract contract ARecoverableAccount is IAccount, Initializable, AAccountRecovery, ERC7821 {
    using Address for *;

    uint256 public constant SIG_VALIDATION_FAILED = 1;
    uint256 public constant SIG_VALIDATION_SUCCESS = 0;

    // bytes32(uint256(keccak256("solarity.contract.RecoverableAccount")) - 1)
    bytes32 private constant RECOVERABLE_ACCOUNT_STORAGE_SLOT =
        0x1de247bdf9b17d80bfda717f00d18263d357388b5e6386f32d078d21c211e49c;

    struct RecoverableAccountStorage {
        address entryPoint;
        address trustedExecutor;
    }

    error NotSelfCalled();
    error InvalidExecutor(address executor);

    event TrustedExecutorUpdated(
        address indexed oldTrustedExecutor,
        address indexed newTrustedExecutor
    );

    modifier onlySelfCalled() {
        _onlySelfCalled();
        _;
    }

    function __ARecoverableAccount_init(
        address entryPoint_,
        address trustedExecutor_
    ) internal onlyInitializing {
        _getRecoverableAccountStorage().entryPoint = entryPoint_;

        _updateTrustedExecutor(trustedExecutor_);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function addRecoveryProvider(
        address provider_,
        bytes memory recoveryData_
    ) external payable virtual override onlySelfCalled {
        _addRecoveryProvider(provider_, recoveryData_, msg.value);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function removeRecoveryProvider(
        address provider_
    ) external payable virtual override onlySelfCalled {
        _removeRecoveryProvider(provider_, msg.value);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function recoverAccess(
        bytes memory subject_,
        address provider_,
        bytes memory proof_
    ) external virtual override returns (bool) {
        _validateRecovery(subject_, provider_, proof_);

        _recoverAccess(subject_);

        emit AccessRecovered(subject_);

        return true;
    }

    /**
     * @inheritdoc IAccount
     */
    function validateUserOp(
        PackedUserOperation calldata userOp_,
        bytes32 userOpHash_,
        uint256 missingAccountFunds_
    ) external virtual returns (uint256 validationData_) {
        _onlyEntryPoint();

        validationData_ = _validateSignature(userOp_, userOpHash_);

        _validateNonce(userOp_.nonce);

        _payPrefund(missingAccountFunds_);
    }

    /**
     * @notice A function to retrieve the current trusted executor.
     * @return The address of the current trusted executor.
     */
    function trustedExecutor() public view virtual returns (address) {
        return _getRecoverableAccountStorage().trustedExecutor;
    }

    /**
     * @inheritdoc IAccount
     */
    function entryPoint() public view virtual returns (address) {
        return _getRecoverableAccountStorage().entryPoint;
    }

    function _recoverAccess(bytes memory subject_) internal virtual {
        address newTrustedExecutor_ = abi.decode(subject_, (address));

        _updateTrustedExecutor(newTrustedExecutor_);
    }

    /**
     * @dev allow execution from address(this), trusted executor, and entrypoint
     */
    function _execute(
        bytes32,
        bytes calldata,
        Call[] calldata calls_,
        bytes calldata
    ) internal virtual override {
        if (
            msg.sender != address(this) &&
            msg.sender != trustedExecutor() &&
            msg.sender != entryPoint()
        ) {
            revert InvalidExecutor(msg.sender);
        }

        _execute(calls_, bytes32(0));
    }

    function _execute(
        address to_,
        uint256 value_,
        bytes calldata data_,
        bytes32
    ) internal virtual override {
        _beforeCall(to_, value_, data_);

        if (data_.length > 0) {
            to_.functionCallWithValue(data_, value_);
        } else {
            payable(to_).sendValue(value_);
        }

        _afterCall(to_, value_, data_);
    }

    function _updateTrustedExecutor(address newTrustedExecutor_) internal virtual {
        address oldTrustedExecutor_ = trustedExecutor();

        _getRecoverableAccountStorage().trustedExecutor = newTrustedExecutor_;

        emit TrustedExecutorUpdated(oldTrustedExecutor_, newTrustedExecutor_);
    }

    /**
     * @dev override this for a custom paymaster logic
     */
    function _payPrefund(uint256 missingAccountFunds_) internal virtual {
        if (missingAccountFunds_ != 0) {
            payable(msg.sender).sendValue(missingAccountFunds_);
        }
    }

    function _validateSignature(
        PackedUserOperation calldata userOp_,
        bytes32 userOpHash_
    ) internal virtual returns (uint256 validationData_) {
        // For gas estimation bundler sets signature as empty
        // and we need to avoid reverting in this case
        if (userOp_.signature.length < 65) {
            return SIG_VALIDATION_FAILED;
        }

        address recovered_ = ECDSA.recover(userOpHash_, userOp_.signature);

        if (recovered_ == address(this) || recovered_ == trustedExecutor()) {
            return SIG_VALIDATION_SUCCESS;
        }

        return SIG_VALIDATION_FAILED;
    }

    function _validateNonce(uint256 nonce_) internal view virtual {}

    function _beforeCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _afterCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _onlyEntryPoint() internal view {
        if (msg.sender != entryPoint()) revert NotAnEntryPoint(msg.sender);
    }

    function _onlySelfCalled() internal view {
        if (msg.sender != address(this)) revert NotSelfCalled();
    }

    function _getRecoverableAccountStorage()
        private
        pure
        returns (RecoverableAccountStorage storage _ras)
    {
        bytes32 slot_ = RECOVERABLE_ACCOUNT_STORAGE_SLOT;

        assembly {
            _ras.slot := slot_
        }
    }
}
