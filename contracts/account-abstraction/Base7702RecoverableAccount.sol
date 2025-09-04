// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {AAccountRecovery} from "./AAccountRecovery.sol";
import {IAccountRecovery} from "../interfaces/account-abstraction/IAccountRecovery.sol";
import {IBatchExecutor} from "../interfaces/account-abstraction/erc-7821/IBatchExecutor.sol";
import {IBase7702RecoverableAccount} from "../interfaces/account-abstraction/IBase7702RecoverableAccount.sol";

contract Base7702RecoverableAccount is
    IBase7702RecoverableAccount,
    AAccountRecovery,
    EIP712,
    Nonces
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant BATCH_EXECUTE_TYPEHASH =
        keccak256("BatchExecute(bytes32 callsHash,uint256 nonce)");

    // bytes32(uint256(keccak256("solarity.contract.Base7702RecoverableAccount")) - 1)
    bytes32 public constant BASE_7702_RECOVERABLE_ACCOUNT_STORAGE_SLOT =
        0xfa0b84e7e8a5ec43e0f9187808211f7ec3edc3033e85aef75ee576effbc39b12;

    struct Base7702RecoverableAccountStorage {
        EnumerableSet.AddressSet trustedExecutors;
    }

    constructor() EIP712("Base7702RecoverableAccount", "v1.0.0") {}

    modifier onlySelfCalled() {
        _onlySelfCalled();
        _;
    }

    /**
     * @inheritdoc IBase7702RecoverableAccount
     */
    function updateTrustedExecutor(
        address trustedExecutor_,
        bool isAdding_
    ) external virtual onlySelfCalled {
        _updateTrustedExecutor(trustedExecutor_, isAdding_);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function addRecoveryProvider(
        address provider_,
        bytes memory recoveryData_
    ) external payable virtual override(IAccountRecovery, AAccountRecovery) onlySelfCalled {
        _addRecoveryProvider(provider_, recoveryData_, msg.value);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function removeRecoveryProvider(
        address provider_
    ) external payable virtual override(IAccountRecovery, AAccountRecovery) onlySelfCalled {
        _removeRecoveryProvider(provider_, msg.value);
    }

    /**
     * @inheritdoc AAccountRecovery
     */
    function recoverAccess(
        bytes memory subject_,
        address provider_,
        bytes memory proof_
    ) external virtual override(IAccountRecovery, AAccountRecovery) returns (bool) {
        _validateRecovery(subject_, provider_, proof_);

        (address trustedExecutor_, bool isAdding_) = abi.decode(subject_, (address, bool));

        _updateTrustedExecutor(trustedExecutor_, isAdding_);

        emit AccessRecovered(subject_);

        return true;
    }

    /**
     * @inheritdoc IBatchExecutor
     */
    function execute(bytes32 mode_, bytes memory executionData_) public payable virtual {
        uint256 id_ = _executionModeId(mode_);

        if (id_ == 0) revert UnsupportedExecutionMode();

        if (id_ == 3) {
            mode_ ^= bytes32(uint256(3 << (22 * 8)));

            bytes[] memory batches_ = abi.decode(executionData_, (bytes[]));

            for (uint256 i = 0; i < batches_.length; ++i) {
                execute(mode_, batches_[i]);
            }

            return;
        }

        Call[] memory calls_;
        bytes memory opData_;

        if (id_ == 2) {
            (calls_, opData_) = abi.decode(executionData_, (Call[], bytes));
        } else {
            calls_ = abi.decode(executionData_, (Call[]));
        }

        _execute(calls_, opData_);
    }

    /**
     * @inheritdoc IBatchExecutor
     */
    function supportsExecutionMode(bytes32 mode_) public view virtual returns (bool) {
        return _executionModeId(mode_) != 0;
    }

    /**
     * @inheritdoc IBatchExecutor
     */
    function hashBatchExecute(
        Call[] memory calls_,
        uint256 nonce_
    ) public view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(BATCH_EXECUTE_TYPEHASH, keccak256(abi.encode(calls_)), nonce_)
                )
            );
    }

    /**
     * @inheritdoc IBase7702RecoverableAccount
     */
    function getTrustedExecutors() public view virtual returns (address[] memory) {
        return _getBase7702RecoverableAccountStorage().trustedExecutors.values();
    }

    function _execute(Call[] memory calls_, bytes memory opData_) internal {
        _beforeBatchCall(calls_, opData_);

        if (opData_.length == 0) {
            _onlySelfOrTrustedExecutor(msg.sender);
        } else {
            bytes memory signature_ = abi.decode(opData_, (bytes));

            bytes32 hash_ = hashBatchExecute(calls_, _useNonce(address(this)));

            address recovered_ = ECDSA.recover(hash_, signature_);

            _onlySelfOrTrustedExecutor(recovered_);
        }

        _execute(calls_);

        _afterBatchCall(calls_, opData_);
    }

    function _execute(Call[] memory calls_) internal {
        for (uint256 i = 0; i < calls_.length; ++i) {
            Call memory call_ = calls_[i];

            address to_ = call_.to == address(0) ? address(this) : call_.to;

            _execute(to_, call_.value, call_.data);
        }
    }

    function _execute(address to_, uint256 value_, bytes memory data_) internal {
        _beforeCall(to_, value_, data_);

        (bool success_, bytes memory result_) = to_.call{value: value_}(data_);

        if (!success_) {
            assembly {
                revert(add(result_, 0x20), mload(result_))
            }
        }

        _afterCall(to_, value_, data_);
    }

    function _updateTrustedExecutor(address trustedExecutor_, bool isAdding_) internal {
        if (isAdding_) {
            _addTrustedExecutor(trustedExecutor_);
        } else {
            _removeTrustedExecutor(trustedExecutor_);
        }
    }

    function _addTrustedExecutor(address newTrustedExecutor_) internal {
        if (!_getBase7702RecoverableAccountStorage().trustedExecutors.add(newTrustedExecutor_)) {
            revert TrustedExecutorAlreadyAdded(newTrustedExecutor_);
        }

        emit TrustedExecutorAdded(newTrustedExecutor_);
    }

    function _removeTrustedExecutor(address trustedExecutor_) internal {
        if (!_getBase7702RecoverableAccountStorage().trustedExecutors.remove(trustedExecutor_)) {
            revert TrustedExecutorNotRegistered(trustedExecutor_);
        }

        emit TrustedExecutorRemoved(trustedExecutor_);
    }

    function _beforeBatchCall(Call[] memory calls_, bytes memory opData_) internal virtual {}

    function _afterBatchCall(Call[] memory calls_, bytes memory opData_) internal virtual {}

    function _beforeCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _afterCall(address to_, uint256 value_, bytes memory data_) internal virtual {}

    function _onlySelfOrTrustedExecutor(address sender_) internal view {
        if (
            sender_ != address(this) &&
            !_getBase7702RecoverableAccountStorage().trustedExecutors.contains(sender_)
        ) revert NotSelfOrTrustedExecutor(sender_);
    }

    function _onlySelfCalled() internal view {
        if (tx.origin != address(this) || tx.origin != msg.sender) revert NotSelfCalled();
    }

    function _executionModeId(bytes32 mode_) internal pure returns (uint256 id_) {
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
