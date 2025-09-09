// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ERC7821} from "solady/src/accounts/ERC7821.sol";

import {AAccountRecovery} from "./AAccountRecovery.sol";
import {IAccount} from "../interfaces/account-abstraction/erc-4337/IAccount.sol";

/**
 * @notice The EIP-7702 Recoverable Account module
 *
 * A basic EIP-7702 account implementation with ERC-7821 batching execution,
 * ERC-4337 sponsored transactions, and recoverable trusted executor.
 */
contract Base7702RecoverableAccount is ERC7821, AAccountRecovery, IAccount {
    uint256 public constant SIG_VALIDATION_FAILED = 1;
    uint256 public constant SIG_VALIDATION_SUCCESS = 0;

    // bytes32(uint256(keccak256("solarity.contract.Base7702RecoverableAccount")) - 1)
    bytes32 private constant BASE_7702_RECOVERABLE_ACCOUNT_STORAGE_SLOT =
        0xfa0b84e7e8a5ec43e0f9187808211f7ec3edc3033e85aef75ee576effbc39b12;

    struct Base7702RecoverableAccountStorage {
        address trustedExecutor;
    }

    error NotSelfCalled();
    error InvalidExecutor(address executor);
    error TrustedExecutorAlreadySet(address trustedExecutor);

    event TrustedExecutorUpdated(
        address indexed oldTrustedExecutor,
        address indexed newTrustedExecutor
    );

    modifier onlySelfCalled() {
        _onlySelfCalled();
        _;
    }

    address internal _entryPoint;

    constructor(address entryPoint_) {
        _entryPoint = entryPoint_;
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
        _requireFromEntryPoint();

        validationData_ = _validateSignature(userOp_, userOpHash_);

        _validateNonce(userOp_.nonce);

        _payPrefund(missingAccountFunds_);
    }

    /**
     * @notice A function to retrieve the current trusted executor.
     * @return The address of the current trusted executor.
     */
    function getTrustedExecutor() public view virtual returns (address) {
        return _getBase7702RecoverableAccountStorage().trustedExecutor;
    }

    /**
     * @inheritdoc IAccount
     */
    function entryPoint() public view virtual returns (address) {
        return _entryPoint;
    }

    function _recoverAccess(bytes memory subject_) internal virtual {
        address newTrustedExecutor_ = abi.decode(subject_, (address));

        _updateTrustedExecutor(newTrustedExecutor_);
    }

    function _execute(
        bytes32,
        bytes calldata,
        Call[] calldata calls_,
        bytes calldata opData_
    ) internal virtual override {
        _beforeBatchCall(calls_, opData_);

        _validateExecution(calls_, opData_);

        _execute(calls_, bytes32(0));

        _afterBatchCall(calls_, opData_);
    }

    function _execute(
        address to_,
        uint256 value_,
        bytes calldata data_,
        bytes32
    ) internal virtual override {
        _beforeCall(to_, value_, data_);

        (bool success_, bytes memory result_) = to_.call{value: value_}(data_);

        if (!success_) {
            assembly {
                revert(add(result_, 0x20), mload(result_))
            }
        }

        _afterCall(to_, value_, data_);
    }

    function _validateExecution(Call[] memory, bytes memory) internal virtual {
        if (
            msg.sender != address(this) &&
            msg.sender != getTrustedExecutor() &&
            msg.sender != entryPoint()
        ) {
            revert InvalidExecutor(msg.sender);
        }
    }

    function _updateTrustedExecutor(address newTrustedExecutor_) internal virtual {
        address oldTrustedExecutor_ = getTrustedExecutor();

        if (oldTrustedExecutor_ == newTrustedExecutor_) {
            revert TrustedExecutorAlreadySet(newTrustedExecutor_);
        }

        _getBase7702RecoverableAccountStorage().trustedExecutor = newTrustedExecutor_;

        emit TrustedExecutorUpdated(oldTrustedExecutor_, newTrustedExecutor_);
    }

    function _payPrefund(uint256 missingAccountFunds_) internal {
        if (missingAccountFunds_ != 0) {
            (bool success_, ) = payable(msg.sender).call{
                value: missingAccountFunds_,
                gas: type(uint256).max
            }("");

            if (!success_) revert PrefundFailed();
        }
    }

    function _validateSignature(
        PackedUserOperation calldata userOp_,
        bytes32 userOpHash_
    ) internal virtual returns (uint256 validationData_) {
        return
            _checkSignature(userOpHash_, userOp_.signature)
                ? SIG_VALIDATION_SUCCESS
                : SIG_VALIDATION_FAILED;
    }

    function _checkSignature(
        bytes32 hash_,
        bytes memory signature_
    ) internal view virtual returns (bool) {
        address recovered_ = ECDSA.recover(hash_, signature_);

        return recovered_ == address(this) || recovered_ == getTrustedExecutor();
    }

    function _validateNonce(uint256 nonce_) internal view virtual {}

    function _beforeBatchCall(Call[] memory calls_, bytes memory opData_) internal virtual {}

    function _afterBatchCall(Call[] memory calls_, bytes memory opData_) internal virtual {}

    function _beforeCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _afterCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _requireFromEntryPoint() internal view {
        if (msg.sender != entryPoint()) revert CallerIsNotAnEntryPoint(msg.sender);
    }

    function _onlySelfCalled() internal view {
        if (tx.origin != address(this) || tx.origin != msg.sender) revert NotSelfCalled();
    }

    function _executionModeId(bytes32 mode_) internal pure virtual override returns (uint256 id_) {
        // Bytes Layout:
        // - [0]      ( 1 byte )  `0x01` for batch call.
        // - [1]      ( 1 byte )  `0x00` for revert on any failure.
        // - [2..5]   ( 4 bytes)  Reserved by ERC7579 for future standardization.
        // - [6..9]   ( 4 bytes)  `0x00000000` or `0x78210001` or `0x78210002`.
        // - [10..31] (22 bytes)  Unused. Free for use.
        uint256 m_ = (uint256(mode_) >> (22 * 8)) & 0xffff00000000ffffffff;

        if (m_ == 0x01000000000078210002) {
            return 3;
        }

        if (m_ == 0x01000000000078210001) {
            return 2;
        }

        if (m_ == 0x01000000000000000000) {
            return 1;
        }

        return 0;
    }

    function _getBase7702RecoverableAccountStorage()
        private
        pure
        returns (Base7702RecoverableAccountStorage storage _bras)
    {
        bytes32 slot_ = BASE_7702_RECOVERABLE_ACCOUNT_STORAGE_SLOT;

        assembly {
            _bras.slot := slot_
        }
    }
}
