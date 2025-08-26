// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title The Bridge Contract
 *
 * The Bridge contract facilitates the permissioned transfer of assets
 * (ERC20, ERC721, ERC1155, Native) between two different EVM blockchains.
 *
 * To utilize the Bridge effectively, instances of the contract must be deployed on both the base and destination chains,
 * accompanied by the setup of a trusted backend to act as a `signer`.
 *
 * The Bridge contract supports both the liquidity pool method and the mint-and-burn method for transferring assets.
 * Users can either deposit or withdraw assets through the contract during a transfer operation.
 *
 * IMPORTANT:
 * All signer addresses must differ in their first (most significant) 8 bits in order to pass a bloom filtering.
 */
interface IBridge {
    enum ERC20BridgingType {
        LiquidityPool,
        Wrapped,
        USDCType
    }

    enum ERC721BridgingType {
        LiquidityPool,
        Wrapped
    }

    enum ERC1155BridgingType {
        LiquidityPool,
        Wrapped
    }

    event DepositedERC20(
        address token,
        uint256 amount,
        string receiver,
        string network,
        ERC20BridgingType operationType
    );

    event DepositedERC721(
        address token,
        uint256 tokenId,
        string receiver,
        string network,
        ERC721BridgingType operationType
    );

    event DepositedERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        string receiver,
        string network,
        ERC1155BridgingType operationType
    );

    event DepositedNative(uint256 amount, string receiver, string network);

    error InvalidSigner(address signer);
    error InvalidSigners();
    error DuplicateSigner(address signer);
    error ThresholdNotMet(uint256 signers);
    error ThresholdIsZero();
    error HashNonceUsed(bytes32 hashNonce);
    error InvalidToken();
    error InvalidReceiver();
    error InvalidAmount();
    error InvalidValue();

    /**
     * @notice Deposits ERC20 tokens for bridging, emitting a `DepositedERC20` event.
     * @param token_ The address of the deposited token.
     * @param amount_ The amount of deposited tokens.
     * @param receiver_ The receiver's address in the destination network, used as an informational field for the event.
     * @param network_ The name of the destination network, used as an informational field for the event.
     * @param operationType_ The type of bridging operation being performed.
     */
    function depositERC20(
        address token_,
        uint256 amount_,
        string calldata receiver_,
        string calldata network_,
        ERC20BridgingType operationType_
    ) external;

    /**
     * @notice Deposits ERC721 tokens for bridging, emitting a `DepositedERC721` event.
     * @param token_ The address of the deposited token.
     * @param tokenId_ The ID of the deposited token.
     * @param receiver_ The receiver's address in the destination network, used as an informational field for the event.
     * @param network_ The name of the destination network, used as an informational field for the event.
     * @param operationType_ The type of bridging operation being performed.
     */
    function depositERC721(
        address token_,
        uint256 tokenId_,
        string calldata receiver_,
        string calldata network_,
        ERC721BridgingType operationType_
    ) external;

    /**
     * @notice Deposits ERC1155 tokens for bridging, emitting a `DepositedERC1155` event.
     * @param token_ The address of the deposited tokens.
     * @param tokenId_ The ID of the deposited tokens.
     * @param amount_ The amount of deposited tokens.
     * @param receiver_ The receiver's address in the destination network, used as an informational field for the event.
     * @param network_ The name of the destination network, used as an informational field for the event.
     * @param operationType_ The type of bridging operation being performed.
     */
    function depositERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata receiver_,
        string calldata network_,
        ERC1155BridgingType operationType_
    ) external;

    /**
     * @notice function for depositing native currency, emits event DepositedNative
     * @param receiver_ the receiver address in destination network, information field for event
     * @param network_ the network name of destination network, information field for event
     */
    function depositNative(string calldata receiver_, string calldata network_) external payable;

    /**
     * @notice Withdraws ERC20 tokens.
     * @param token_ The address of the token to withdraw.
     * @param amount_ The amount of tokens to withdraw.
     * @param receiver_ The address of the withdrawal recipient.
     * @param txHash_ The hash of the deposit transaction.
     * @param txNonce_ The nonce of the deposit transaction.
     * @param operationType_ The type of bridging operation.
     * @param signatures_ An array of signatures, formed by signing a sign hash by each signer.
     */
    function withdrawERC20(
        address token_,
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        ERC20BridgingType operationType_,
        bytes[] calldata signatures_
    ) external;

    /**
     * @notice Withdraws ERC721 tokens.
     * @param token_ The address of the token to withdraw.
     * @param tokenId_ The ID of the token to withdraw.
     * @param receiver_ The address of the withdrawal recipient.
     * @param txHash_ The hash of the deposit transaction.
     * @param txNonce_ The nonce of the deposit transaction.
     * @param tokenURI_ The string URI of the token metadata.
     * @param operationType_ The type of bridging operation.
     * @param signatures_ An array of signatures, formed by signing a sign hash by each signer.
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
    ) external;

    /**
     * @notice Withdraws ERC1155 tokens.
     * @param token_ The address of the token to withdraw.
     * @param tokenId_ The ID of the token to withdraw.
     * @param amount_ The amount of tokens to withdraw.
     * @param receiver_ The address of the withdrawal recipient.
     * @param txHash_ The hash of the deposit transaction.
     * @param txNonce_ The nonce of the deposit transaction.
     * @param tokenURI_ The string URI of the token metadata.
     * @param operationType_ The type of bridging operation.
     * @param signatures_ An array of signatures, formed by signing a sign hash by each signer.
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
    ) external;

    /**
     * @notice Withdraws native currency.
     * @param amount_ The amount of native currency to withdraw.
     * @param receiver_ The address of the withdrawal recipient.
     * @param txHash_ The hash of the deposit transaction.
     * @param txNonce_ The nonce of the deposit transaction.
     * @param signatures_ An array of signatures, formed by signing a sign hash by each signer.
     */
    function withdrawNative(
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        bytes[] calldata signatures_
    ) external;
}
