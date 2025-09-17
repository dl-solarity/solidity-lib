// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {IBridge} from "../interfaces/bridge/IBridge.sol";
import {IHandler} from "../interfaces/bridge/IHandler.sol";

import {IBatcher, Batcher} from "./batcher/Batcher.sol";

/**
 * @notice The Bridge module
 *
 * The Bridge contract facilitates the permissioned transfer of assets and/or arbitrary messages
 * between two (or more) EVM blockchains.
 *
 * To utilize the Bridge effectively, instances of this contract must be deployed on both base
 * and destination chains, accompanied by the setup of trusted back ends to act as signers.
 * The back end signatures are checked only upon redemption.
 *
 * Each asset type is mapped to a handler (ERC-20, Native, Message) contract.
 * Handlers implement the specific dispatch/redeem logic.
 *
 * During redeem, handlers may forward execution to the `IBatcher` contract for multi-step operations.
 * The bridge never executes batches directly and does this via a designated `batcher` contract
 * that can be overridden. Users are advised to construct tx batches in a way that
 * they are not front-runnable. E.g., USDT approve should be reset first.
 *
 * IMPORTANT:
 * All signer addresses must differ in their first (most significant) 8 bits
 * in order to pass bloom (uniqueness) filtering.
 */
abstract contract ABridge is IBridge, Initializable {
    using Address for address;
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct ABridgeStorage {
        string network;
        IBatcher batcher;
        EnumerableMap.UintToAddressMap handlers;
        EnumerableSet.AddressSet signers;
        uint256 signaturesThreshold;
        mapping(bytes32 => bool) usedNonce;
    }

    // bytes32(uint256(keccak256("solarity.contract.ABridge")) - 1)
    bytes32 private constant A_BRIDGE_STORAGE =
        0xc353df91453f9451d14bc3d78b643ca35222ee145cc2e80765c8a1e293a85ff7;

    /**
     * @notice The initialization function.
     * @param network_ the network name.
     * @param assetTypes_ list of asset type identifiers to link handlers to.
     * @param handlers_ list of handler contract addresses corresponding to `assetTypes_`.
     * @param signers_ list of authorized signer addresses.
     * @param signaturesThreshold_ minimum number of signer approvals required for redemption.
     */
    function __ABridge_init(
        string memory network_,
        uint256[] memory assetTypes_,
        address[] memory handlers_,
        address[] memory signers_,
        uint256 signaturesThreshold_
    ) internal onlyInitializing {
        ABridgeStorage storage $ = _getABridgeStorage();

        _setBatcher(_batcher());
        _addSigners(signers_);
        _setSignaturesThreshold(signaturesThreshold_);

        for (uint256 i = 0; i < assetTypes_.length; ++i) {
            _addHandler(assetTypes_[i], handlers_[i]);
        }

        $.network = network_;
    }

    /**
     * @inheritdoc IBridge
     */
    function dispatch(
        uint256 assetType_,
        bytes calldata dispatchDetails_
    ) external payable virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        if (!assetTypeSupported(assetType_)) revert HandlerDoesNotExist(assetType_);

        address handler_ = $.handlers.get(assetType_);

        handler_.functionDelegateCall(
            abi.encodeWithSelector(IHandler.dispatch.selector, dispatchDetails_)
        );
    }

    /**
     * @inheritdoc IBridge
     */
    function redeem(
        uint256 assetType_,
        bytes calldata redeemDetails_,
        bytes calldata proof_
    ) external virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        if (!assetTypeSupported(assetType_)) revert HandlerDoesNotExist(assetType_);

        address handler_ = $.handlers.get(assetType_);

        bytes32 operationHash_ = IHandler(handler_).getOperationHash($.network, redeemDetails_);

        _checkAndUpdateNonce(operationHash_);
        _checkSignatures(operationHash_, abi.decode(proof_, (bytes[])));

        handler_.functionDelegateCall(
            abi.encodeWithSelector(IHandler.redeem.selector, $.batcher, redeemDetails_)
        );
    }

    /**
     * @notice Returns the list of supported asset types and a list of their corresponding handlers
     */
    function getHandlers()
        external
        view
        returns (uint256[] memory assetTypes_, address[] memory handlers_)
    {
        ABridgeStorage storage $ = _getABridgeStorage();

        assetTypes_ = $.handlers.keys();

        handlers_ = new address[](assetTypes_.length);

        for (uint256 i = 0; i < assetTypes_.length; ++i) {
            handlers_[i] = $.handlers.get(assetTypes_[i]);
        }
    }

    /**
     * @notice Returns the network name
     */
    function getNetwork() external view returns (string memory) {
        return _getABridgeStorage().network;
    }

    /**
     * @notice Returns the address of the batcher used
     */
    function getBatcher() external view returns (address) {
        return address(_getABridgeStorage().batcher);
    }

    /**
     * @notice Returns the list of current bridge signers
     */
    function getSigners() external view returns (address[] memory) {
        return _getABridgeStorage().signers.values();
    }

    /**
     * @notice Returns the number of signatures for the redemption to be accepted
     */
    function getSignaturesThreshold() external view returns (uint256) {
        return _getABridgeStorage().signaturesThreshold;
    }

    /**
     * @notice Checks if the dispatch event exists in the contract
     */
    function nonceUsed(bytes32 nonce_) external view returns (bool) {
        return _getABridgeStorage().usedNonce[nonce_];
    }

    /**
     * @notice Checks if the asset type is linked to the handler
     */
    function assetTypeSupported(uint256 assetType_) public view returns (bool) {
        return _getABridgeStorage().handlers.contains(assetType_);
    }

    /**
     * @dev Should be access controlled and made public in the descendant contracts
     */
    function _addHandler(uint256 assetType_, address handler_) internal virtual {
        if (handler_ == address(0)) revert ZeroHandler();

        if (!_getABridgeStorage().handlers.set(assetType_, handler_))
            revert HandlerAlreadyPresent(assetType_);
    }

    /**
     * @dev Should be access controlled and made public in the descendant contracts
     */
    function _removeHandler(uint256 assetType_) internal virtual {
        if (!_getABridgeStorage().handlers.remove(assetType_))
            revert HandlerDoesNotExist(assetType_);
    }

    /**
     * @dev Should be access controlled and made public in the descendant contracts
     */
    function _setSignaturesThreshold(uint256 signaturesThreshold_) internal virtual {
        if (signaturesThreshold_ == 0) revert ThresholdIsZero();

        _getABridgeStorage().signaturesThreshold = signaturesThreshold_;
    }

    /**
     * @dev Should be access controlled and made public in the descendant contracts
     */
    function _addSigners(address[] memory signers_) internal virtual {
        if (signers_.length == 0) revert InvalidSigners();

        ABridgeStorage storage $ = _getABridgeStorage();

        for (uint256 i = 0; i < signers_.length; ++i) {
            if (signers_[i] == address(0)) revert InvalidSigner(signers_[i]);

            $.signers.add(signers_[i]);
        }
    }

    /**
     * @dev Should be access controlled and made public in the descendant contracts
     */
    function _removeSigners(address[] memory signers_) internal virtual {
        if (signers_.length == 0) revert InvalidSigners();

        ABridgeStorage storage $ = _getABridgeStorage();

        for (uint256 i = 0; i < signers_.length; ++i) {
            $.signers.remove(signers_[i]);
        }
    }

    function _setBatcher(IBatcher batcher_) internal virtual {
        _getABridgeStorage().batcher = batcher_;
    }

    /**
     * @dev Override this function for a custom batcher deployment
     */
    function _batcher() internal virtual returns (IBatcher) {
        return new Batcher();
    }

    function _checkAndUpdateNonce(bytes32 nonce_) internal virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        if ($.usedNonce[nonce_]) revert NonceUsed(nonce_);

        $.usedNonce[nonce_] = true;
    }

    function _checkSignatures(
        bytes32 signHash_,
        bytes[] memory signatures_
    ) internal view virtual {
        address[] memory signers_ = new address[](signatures_.length);

        for (uint256 i = 0; i < signatures_.length; ++i) {
            signers_[i] = signHash_.toEthSignedMessageHash().recover(signatures_[i]);
        }

        _checkCorrectSigners(signers_);
    }

    function _checkCorrectSigners(address[] memory signers_) internal view virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        uint256 bitMap_;

        for (uint256 i = 0; i < signers_.length; ++i) {
            address signer_ = signers_[i];

            if (!$.signers.contains(signer_)) revert InvalidSigner(signer_);

            // get the topmost byte for bloom filtering
            uint256 bitKey_ = 2 ** (uint256(uint160(signer_)) >> 152);

            if (bitMap_ & bitKey_ != 0) revert DuplicateSigner(signer_);

            bitMap_ |= bitKey_;
        }

        if (signers_.length < $.signaturesThreshold) revert ThresholdNotMet(signers_.length);
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getABridgeStorage() private pure returns (ABridgeStorage storage $) {
        assembly {
            $.slot := A_BRIDGE_STORAGE
        }
    }
}
