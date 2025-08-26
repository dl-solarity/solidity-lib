// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IBridge} from "../interfaces/bridge/IBridge.sol";

import {AERC20Handler} from "./handlers/AERC20Handler.sol";
import {AERC721Handler} from "./handlers/AERC721Handler.sol";
import {AERC1155Handler} from "./handlers/AERC1155Handler.sol";
import {ANativeHandler} from "./handlers/ANativeHandler.sol";

/**
 * @title Bridge Contract
 */
abstract contract ABridge is
    IBridge,
    Initializable,
    AERC20Handler,
    AERC721Handler,
    AERC1155Handler,
    ANativeHandler
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ABridgeStorage {
        uint256 signaturesThreshold;
        mapping(bytes32 => bool) usedHashes; // keccak256(txHash . txNonce) => is used
        EnumerableSet.AddressSet signers;
    }

    // bytes32(uint256(keccak256("solarity.contract.ABridge")) - 1)
    bytes32 private constant A_BRIDGE_STORAGE =
        0xc353df91453f9451d14bc3d78b643ca35222ee145cc2e80765c8a1e293a85ff7;

    function __Bridge_init(
        address[] calldata signers_,
        uint256 signaturesThreshold_
    ) internal onlyInitializing {
        _addSigners(signers_);
        _setSignaturesThreshold(signaturesThreshold_);
    }

    /**
     * @inheritdoc IBridge
     */
    function depositERC20(
        address token_,
        uint256 amount_,
        string calldata receiver_,
        string calldata network_,
        ERC20BridgingType operationType_
    ) external virtual override {
        _depositERC20(token_, amount_, operationType_);

        emit DepositedERC20(token_, amount_, receiver_, network_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function depositERC721(
        address token_,
        uint256 tokenId_,
        string calldata receiver_,
        string calldata network_,
        ERC721BridgingType operationType_
    ) external virtual override {
        _depositERC721(token_, tokenId_, operationType_);

        emit DepositedERC721(token_, tokenId_, receiver_, network_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function depositERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata receiver_,
        string calldata network_,
        ERC1155BridgingType operationType_
    ) external virtual override {
        _depositERC1155(token_, tokenId_, amount_, operationType_);

        emit DepositedERC1155(token_, tokenId_, amount_, receiver_, network_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function depositNative(
        string calldata receiver_,
        string calldata network_
    ) external payable virtual override {
        _depositNative();

        emit DepositedNative(msg.value, receiver_, network_);
    }

    /**
     * @inheritdoc IBridge
     */
    function withdrawERC20(
        address token_,
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        ERC20BridgingType operationType_,
        bytes[] calldata signatures_
    ) external virtual override {
        bytes32 signHash_ = getERC20SignHash(
            token_,
            amount_,
            receiver_,
            txHash_,
            txNonce_,
            block.chainid,
            operationType_
        );

        _checkAndUpdateHashes(txHash_, txNonce_);
        _checkSignatures(signHash_, signatures_);

        _withdrawERC20(token_, amount_, receiver_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function withdrawERC721(
        address token_,
        uint256 tokenId_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        string calldata tokenURI_,
        ERC721BridgingType operationType_,
        bytes[] calldata signatures_
    ) external virtual override {
        bytes32 signHash_ = getERC721SignHash(
            token_,
            tokenId_,
            receiver_,
            txHash_,
            txNonce_,
            block.chainid,
            tokenURI_,
            operationType_
        );

        _checkAndUpdateHashes(txHash_, txNonce_);
        _checkSignatures(signHash_, signatures_);

        _withdrawERC721(token_, tokenId_, receiver_, tokenURI_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function withdrawERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        string calldata tokenURI_,
        ERC1155BridgingType operationType_,
        bytes[] calldata signatures_
    ) external virtual override {
        bytes32 signHash_ = getERC1155SignHash(
            token_,
            tokenId_,
            amount_,
            receiver_,
            txHash_,
            txNonce_,
            block.chainid,
            tokenURI_,
            operationType_
        );

        _checkAndUpdateHashes(txHash_, txNonce_);
        _checkSignatures(signHash_, signatures_);

        _withdrawERC1155(token_, tokenId_, amount_, receiver_, tokenURI_, operationType_);
    }

    /**
     * @inheritdoc IBridge
     */
    function withdrawNative(
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        bytes[] calldata signatures_
    ) external virtual override {
        bytes32 signHash_ = getNativeSignHash(
            amount_,
            receiver_,
            txHash_,
            txNonce_,
            block.chainid
        );

        _checkAndUpdateHashes(txHash_, txNonce_);
        _checkSignatures(signHash_, signatures_);

        _withdrawNative(amount_, receiver_);
    }

    function getSigners() external view returns (address[] memory) {
        return _getABridgeStorage().signers.values();
    }

    function getSignaturesThreshold() external view returns (uint256) {
        return _getABridgeStorage().signaturesThreshold;
    }

    function containsHash(bytes32 txHash_, uint256 txNonce_) external view returns (bool) {
        bytes32 nonceHash_ = keccak256(abi.encodePacked(txHash_, txNonce_));

        return _getABridgeStorage().usedHashes[nonceHash_];
    }

    function _setSignaturesThreshold(uint256 signaturesThreshold_) internal virtual {
        require(signaturesThreshold_ > 0, "Signers: invalid threshold");

        _getABridgeStorage().signaturesThreshold = signaturesThreshold_;
    }

    function _addSigners(address[] memory signers_) internal virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        for (uint256 i = 0; i < signers_.length; ++i) {
            require(signers_[i] != address(0), "Signers: zero signer");

            $.signers.add(signers_[i]);
        }
    }

    function _removeSigners(address[] memory signers_) internal virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        for (uint256 i = 0; i < signers_.length; ++i) {
            $.signers.remove(signers_[i]);
        }
    }

    /**
     * @dev txHash_ is the transaction hash on the base chain, txNonce_ is the ordinal number of the deposit event
     */
    function _checkAndUpdateHashes(bytes32 txHash_, uint256 txNonce_) internal virtual {
        ABridgeStorage storage $ = _getABridgeStorage();

        bytes32 nonceHash_ = keccak256(abi.encodePacked(txHash_, txNonce_));

        require(!$.usedHashes[nonceHash_], "Hashes: the hash nonce is used");

        $.usedHashes[nonceHash_] = true;
    }

    function _checkSignatures(
        bytes32 signHash_,
        bytes[] calldata signatures_
    ) internal view virtual {
        address[] memory signers_ = new address[](signatures_.length);

        for (uint256 i = 0; i < signatures_.length; i++) {
            signers_[i] = signHash_.toEthSignedMessageHash().recover(signatures_[i]);
        }

        _checkCorrectSigners(signers_);
    }

    function _checkCorrectSigners(address[] memory signers_) private view {
        ABridgeStorage storage $ = _getABridgeStorage();

        uint256 bitMap;

        for (uint256 i = 0; i < signers_.length; i++) {
            require($.signers.contains(signers_[i]), "Signers: invalid signer");

            // get the topmost byte for the bloom filtering
            uint256 bitKey = 2 ** (uint256(uint160(signers_[i])) >> 152);

            require(bitMap & bitKey == 0, "Signers: duplicate signers");

            bitMap |= bitKey;
        }

        require(signers_.length >= $.signaturesThreshold, "Signers: threshold is not met");
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
