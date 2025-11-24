---
title: Dl Solarity Solidity Lib

---

# Dl Solarity Solidity Lib

**Zero Cool Nexus Review**

*Generated: November 18, 2025 at 05:56 PM*

## Table of Contents

1. [Findings Summary](#Findings-Summary)
2. [Critical Findings](#Critical-Findings) (2)
3. [High Findings](#High-Findings) (4)
4. [Medium Findings](#Medium-Findings) (1)
5. [Low Findings](#Low-Findings) (6)
6. [Info Findings](#Info-Findings) (2)
7. [Statistics](#Statistics)

## Findings Summary

| ID | Title | Severity |
|---|---|---|
| [C-01](#C-01-Cartesian-Merkle-Tree-non-membership-proofs-are-not-bound-to-the-queried-key) | Cartesian Merkle Tree non-membership proofs are not bound to the queried key | <span style="color: #dc2626; font-weight: bold;">CRITICAL</span> |
| [C-02](#C-02-onlySelfCalled-guard-is-unsatisfiable-under-ERC-4337-blocking-recovery-provider-management) | onlySelfCalled guard is unsatisfiable under ERC-4337, blocking recovery provider management | <span style="color: #dc2626; font-weight: bold;">CRITICAL</span> |
| [H-01](#H-01-Operation-hash-bound-to-handler-address-enables-cross-bridge-replay-and-breaks-redemptions-after-handler-upgrade) | Operation hash bound to handler address enables cross-bridge replay and breaks redemptions after handler upgrade | <span style="color: #ea580c; font-weight: bold;">HIGH</span> |
| [H-02](#H-02-OwnableDiamond-lacks-owner-initialization-locking-diamondCut-and-bricking-upgrades) | OwnableDiamond lacks owner initialization, locking diamondCut and bricking upgrades | <span style="color: #ea580c; font-weight: bold;">HIGH</span> |
| [H-03](#H-03-Custom-hasher-function-pointers-stored-in-storage-are-upgrade-unsafe) | Custom hasher function pointers stored in storage are upgrade-unsafe | <span style="color: #ea580c; font-weight: bold;">HIGH</span> |
| [H-04](#H-04-PriorityQueueremove-breaks-heap-invariant-due-to-missing-upward-reheapification) | PriorityQueue.remove breaks heap invariant due to missing upward reheapification | <span style="color: #ea580c; font-weight: bold;">HIGH</span> |
| [M-01](#M-01-Deterministic-treap-priorities-allow-adversarial-worst-case-height-causing-gas-DoS) | Deterministic treap priorities allow adversarial worst-case height causing gas DoS | <span style="color: #d97706; font-weight: bold;">MEDIUM</span> |
| [L-01](#L-01-CartesianMerkleTreeverifyProof-can-revert-on-malformed-proofs-due-to-missing-siblings-length-validation) | CartesianMerkleTree.verifyProof can revert on malformed proofs due to missing siblings-length validation | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [L-02](#L-02-U512modsub-returns-m-instead-of-0-when-a-≡-b-mod-m-in-negative-branch) | U512.modsub returns m instead of 0 when a ≡ b (mod m) in negative branch | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [L-03](#L-03-RSA-PSS-maskedDB-top-bit-check-is-incorrect-allowing-non-compliant-encodings-to-pass-verification) | RSA-PSS maskedDB top-bit check is incorrect, allowing non-compliant encodings to pass verification | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [L-04](#L-04-Bitcoin-TxParser-rejects-versions->2-causing-txid-calculation-revert-and-DoS-for-BTC-inclusion-verification) | Bitcoin TxParser rejects versions >2, causing txid calculation revert and DoS for BTC inclusion verification | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [L-05](#L-05-RSASSA-PSS-leading-bits-check-is-ineffective-and-sigBits-computed-incorrectly) | RSASSA-PSS leading-bits check is ineffective and sigBits computed incorrectly | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [L-06](#L-06-Vector-memory-arithmetic-overflows-enable-in-call-memory-corruption-and-DoS-for-huge-lengths) | Vector memory arithmetic overflows enable in-call memory corruption and DoS for huge lengths | <span style="color: #65a30d; font-weight: bold;">LOW</span> |
| [I-01](#I-01-Missing-schedule-validation-in-vesting-creation-enables-bricked-vestings-via-divide-by-zero) | Missing schedule validation in vesting creation enables bricked vestings via divide-by-zero | <span style="color: #0891b2; font-weight: bold;">INFO</span> |
| [I-02](#I-02-RSASSA-PSS-verifier-fails-maskedDB-top-bit-check-accepting-malformed-encodings) | RSASSA-PSS verifier fails maskedDB top-bit check, accepting malformed encodings | <span style="color: #0891b2; font-weight: bold;">INFO</span> |

## Findings

## Critical Findings

### [C-01] Cartesian Merkle Tree non-membership proofs are not bound to the queried key

#### Summary

The Cartesian Merkle Tree implementation contains a critical flaw in its non-membership proof verification logic that allows attackers to forge valid non-existence proofs for arbitrary keys. The verification process uses the `nonExistenceKey` field to reconstruct the root hash while completely ignoring the actual queried key (`proof.key`), enabling bypass of blacklist checks, uniqueness constraints, and other security mechanisms that rely on proving key absence.

#### Description

The vulnerability exists in the `_verifyProof()` and `_processProof()` functions where non-existence proof verification fails to bind the proof to the queried key. When `proof.existence == false`, the verification algorithm computes the root hash using `proof.nonExistenceKey` and sibling data without enforcing any relationship between the queried key and the auxiliary existing key on the path.

The core issue manifests in the `_processProof()` function at lines 963-967, where the hash computation selects between `proof.key` for existence proofs and `proof.nonExistenceKey` for non-existence proofs:

```solidity
bytes32 computedHash_ = hash3_(
    proof_.existence ? proof_.key : proof_.nonExistenceKey,
    leftHash_,
    rightHash_
);
```

For non-existence proofs, this completely ignores `proof.key`, making the verification independent of the actual key being queried. The only validation in `_verifyProof()` at lines 936-940 merely checks that `nonExistenceKey` is not zero, which does not prevent key-agnostic forging.

An attacker can exploit this by taking any valid inclusion proof for an existing key `K'` and converting it into a "non-existence" proof for any arbitrary target key `X` by setting `existence = false`, `nonExistenceKey = K'`, and `key = X` while reusing the same siblings and direction bits. The verification will succeed because it reconstructs the correct root using the legitimate inclusion proof data while ignoring the forged target key.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:936-948](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L936-L948)

</summary>

```solidity
    function _verifyProof(CMT storage treaple, Proof memory proof_) private view returns (bool) {
        // invalid exclusion proof
        if (!proof_.existence && proof_.nonExistenceKey == ZERO_HASH) {
            return false;
        }

        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
            .isCustomHasherSet
            ? treaple.hash3
            : _hash3;

        return _processProof(hash3_, proof_) == proof_.root;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:950-987](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L950-L987)

</summary>

```solidity
    function _processProof(
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_,
        Proof memory proof_
    ) private view returns (bytes32) {
        bool directionBit_ = _extractDirectionBit(proof_.directionBits, 0);

        bytes32 leftHash_ = proof_.siblings[proof_.siblingsLength - 2];
        bytes32 rightHash_ = proof_.siblings[proof_.siblingsLength - 1];

        if (directionBit_) {
            (leftHash_, rightHash_) = (rightHash_, leftHash_);
        }

        bytes32 computedHash_ = hash3_(
            proof_.existence ? proof_.key : proof_.nonExistenceKey,
            leftHash_,
            rightHash_
        );

        for (uint256 i = 2; i < proof_.siblingsLength; i += 2) {
            directionBit_ = _extractDirectionBit(proof_.directionBits, i);

            leftHash_ = computedHash_;
            rightHash_ = proof_.siblings[proof_.siblingsLength - i - 1];

            if (directionBit_) {
                (leftHash_, rightHash_) = (rightHash_, leftHash_);
            }

            computedHash_ = hash3_(
                proof_.siblings[proof_.siblingsLength - i - 2],
                leftHash_,
                rightHash_
            );
        }

        return computedHash_;
    }
```
</details>

#### Impact Explanation

This vulnerability enables systemic bypass of non-membership-based security checks across any consumer contract relying on CMT non-existence proofs. Attackers can circumvent blacklist mechanisms, violate uniqueness constraints by proving "unused" keys are available for reuse, and bypass any logic requiring proof of key absence. The impact extends to all uses of the verification algorithm for exclusion proofs, as the flaw stems from the core proof verification logic rather than specific implementation choices.

#### Likelihood Explanation

The attack has high likelihood as it requires only an inclusion proof for any existing key in the tree, which can typically be derived off-chain from publicly available data. The exploit is straightforward to execute and does not require special on-chain preconditions beyond a consumer contract accepting user-supplied non-membership proofs—a common pattern for on-chain verification against off-chain-maintained Merkle roots.

#### Recommendation

Consider implementing proper binding between the queried key and non-existence proof by validating the path relationship during verification. One approach could be to verify that the queried key would indeed terminate at an empty child position from the provided `nonExistenceKey` node, ensuring the non-existence proof actually corresponds to the requested key.

The remediation should enforce ordering constraints that tie `proof.key` to the auxiliary node path, such as verifying binary search tree ordering relationships or confirming that following the path for `proof.key` from `nonExistenceKey` leads to an empty position. This would prevent attackers from reusing arbitrary inclusion proofs as non-existence proofs for unrelated keys.

Additionally, consider enhancing the proof structure to include explicit path validation data that can be verified during the non-existence check, ensuring the proof genuinely demonstrates absence of the specific queried key rather than just successful root reconstruction.

### [C-02] onlySelfCalled guard is unsatisfiable under ERC-4337, blocking recovery provider management

#### Summary

The `onlySelfCalled` modifier in `ARecoverableAccount` contains a logical flaw that makes it impossible to satisfy under ERC-4337 execution. The guard requires `tx.origin` to equal the contract address, but under ERC-4337, `tx.origin` is always the bundler EOA. This creates a permanent denial of service for recovery provider management functions, effectively disabling the core recovery functionality of the account system.

#### Description

The `_onlySelfCalled()` function implements an authorization check with the condition `tx.origin != address(this) || tx.origin != msg.sender`. This check is designed to ensure that certain functions can only be called by the account itself. However, the implementation contains a fundamental flaw in its understanding of transaction execution contexts.

Under ERC-4337, transactions are submitted by bundlers (which are EOAs) on behalf of account contracts. In this execution model, `tx.origin` represents the bundler's address and can never equal `address(this)` (the account contract address). The logical OR condition in the guard means that if either `tx.origin != address(this)` OR `tx.origin != msg.sender` is true, the function reverts. Since `tx.origin != address(this)` is always true under ERC-4337, the guard always triggers a revert regardless of the caller.

This affects critical recovery management functions including `addRecoveryProvider()` and `removeRecoveryProvider()`, which are protected by the `onlySelfCalled` modifier. These functions are essential for configuring the account's recovery capabilities, and their inaccessibility prevents users from setting up or maintaining recovery providers.

#### Affected Code

<details>
<summary>

[contracts/account-abstraction/ARecoverableAccount.sol:42-45](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/account-abstraction/ARecoverableAccount.sol#L42-L45)

</summary>

```solidity
    modifier onlySelfCalled() {
        _onlySelfCalled();
        _;
    }
```
</details>

<details>
<summary>

[contracts/account-abstraction/ARecoverableAccount.sol:59-65](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/account-abstraction/ARecoverableAccount.sol#L59-L65)

</summary>

```solidity
    function addRecoveryProvider(
        address provider_,
        bytes memory recoveryData_
    ) external payable virtual override onlySelfCalled {
        _addRecoveryProvider(provider_, recoveryData_, msg.value);
    }
```
</details>

<details>
<summary>

[contracts/account-abstraction/ARecoverableAccount.sol:69-73](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/account-abstraction/ARecoverableAccount.sol#L69-L73)

</summary>

```solidity
    function removeRecoveryProvider(
        address provider_
    ) external payable virtual override onlySelfCalled {
        _removeRecoveryProvider(provider_, msg.value);
    }
```
</details>

<details>
<summary>

[contracts/account-abstraction/ARecoverableAccount.sol:207-209](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/account-abstraction/ARecoverableAccount.sol#L207-L209)

</summary>

```solidity
    function _onlySelfCalled() internal view {
        if (tx.origin != address(this) || tx.origin != msg.sender) revert NotSelfCalled();
    }
```
</details>

#### Impact Explanation

The faulty guard creates a complete denial of service for recovery provider lifecycle management. Users cannot register new recovery providers or remove existing ones, which fundamentally breaks the recovery functionality of the account system. Since recovery flows require registered providers, the `recoverAccess` functionality becomes effectively unusable. This leaves users without the ability to recover their accounts through the intended recovery mechanisms, potentially resulting in permanent loss of access if primary authentication methods fail.

#### Likelihood Explanation

The condition failure is deterministic and occurs on every attempt to call the protected functions under ERC-4337 execution. Since `tx.origin` in ERC-4337 is always the bundler EOA and never equals the contract address, the guard consistently prevents legitimate usage. This affects all users and deployments that rely on ERC-4337 flows, making it a guaranteed failure scenario rather than an edge case.

#### Recommendation

Consider revising the authorization logic in `_onlySelfCalled()` to properly accommodate ERC-4337 execution contexts. One approach could be to replace the `tx.origin` check with a `msg.sender` validation that ensures the call originates from the account itself:

```diff
function _onlySelfCalled() internal view {
-   if (tx.origin != address(this) || tx.origin != msg.sender) revert NotSelfCalled();
+   if (msg.sender != address(this)) revert NotSelfCalled();
}
```

This change would allow the guard to function correctly when the account calls these functions through its own execution context, whether via ERC-4337 UserOperations or direct contract interactions, while still preventing external callers from bypassing the intended access control.

## High Findings

### [H-01] Operation hash bound to handler address enables cross-bridge replay and breaks redemptions after handler upgrade

#### Summary

The bridge system computes operation hashes using handler contract addresses rather than the bridge instance address, creating two critical vulnerabilities. This design flaw enables cross-bridge replay attacks where the same signed operation can be redeemed multiple times across different bridge instances, and causes redemption failures when handler contracts are upgraded. The issue affects the fundamental authorization mechanism of the bridge system.

#### Description

The bridge's authorization mechanism contains a critical design flaw in how operation hashes are computed for signature verification. When `ABridge.redeem()` is called, it retrieves the operation hash by making an external call to the handler contract's `getOperationHash()` function at line 118. All handler implementations include `address(this)` in their hash computation, which resolves to the handler contract address rather than the calling bridge instance.

This creates two distinct attack vectors. First, if multiple bridge instances are configured to use the same handler contract address and share the same network string, signer set, and threshold configuration, they will compute identical operation hashes for the same redemption data. Since each bridge maintains its own independent nonce tracking via the `usedNonce` mapping, the same signed operation can be successfully redeemed on multiple bridge instances.

Second, when a bridge upgrades its handler mapping to point to a new handler contract, the operation hash domain changes. Any redemption operations that were signed using the previous handler address will no longer verify correctly, as the bridge now computes a different operation hash using the new handler address. This renders previously authorized but unredeemed operations permanently unredeemable unless they are re-signed.

The root cause lies in the external call pattern where `ABridge.redeem()` calls `IHandler(handler_).getOperationHash()` as a view function. Within the handler contract's execution context, `address(this)` refers to the handler contract itself, not the bridge instance that maintains state and enforces nonces.

#### Affected Code

<details>
<summary>

[contracts/bridge/ABridge.sol:118](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/bridge/ABridge.sol#L118)

</summary>

```solidity
        bytes32 operationHash_ = IHandler(handler_).getOperationHash($.network, redeemDetails_);
```
</details>

<details>
<summary>

[contracts/bridge/handlers/ERC20Handler.sol:103-115](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/bridge/handlers/ERC20Handler.sol#L103-L115)

</summary>

```solidity
        return
            keccak256(
                abi.encodePacked(
                    redeem_.token,
                    redeem_.amount,
                    redeem_.receiver,
                    redeem_.batch,
                    redeem_.operationType,
                    redeem_.nonce,
                    network_,
                    address(this)
                )
            );
```
</details>

<details>
<summary>

[contracts/bridge/handlers/NativeHandler.sol:70-80](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/bridge/handlers/NativeHandler.sol#L70-L80)

</summary>

```solidity
        return
            keccak256(
                abi.encodePacked(
                    redeem_.amount,
                    redeem_.receiver,
                    redeem_.batch,
                    redeem_.nonce,
                    network_,
                    address(this)
                )
            );
```
</details>

<details>
<summary>

[contracts/bridge/handlers/MessageHandler.sol:53](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/bridge/handlers/MessageHandler.sol#L53)

</summary>

```solidity
        return keccak256(abi.encodePacked(redeem_.batch, redeem_.nonce, network_, address(this)));
```
</details>

#### Impact Explanation

The vulnerability enables double redemption attacks that can inflate token supplies or drain liquidity pools. For wrapped tokens and USDC-type assets, successful exploitation results in unauthorized minting on secondary bridge instances, directly inflating the total supply. For liquidity pool operations, the secondary bridge transfers assets from its own reserves, potentially draining the pool if sufficient operations are replayed. Additionally, handler upgrades cause immediate liveness failures for all pending redemptions signed under the previous handler address, effectively freezing user funds until manual intervention occurs.

#### Likelihood Explanation

Exploitation requires multiple bridge instances configured with shared handler contracts and identical signer configurations, which represents a realistic deployment pattern for gas optimization and operational efficiency. Handler upgrades are routine maintenance operations that will reliably trigger the liveness issue without careful coordination. Once valid signatures exist for any operation, any user can execute the replay attack without requiring special privileges or technical sophistication.

#### Recommendation

Consider modifying the operation hash computation to include the bridge contract address rather than the handler address. One approach could be to have the bridge pass its own address to the handler's `getOperationHash()` function, or compute the hash directly within the bridge using handler-provided data structures. This would ensure that signatures are properly scoped to the specific bridge instance that maintains nonces and executes redemptions.

For the upgrade scenario, consider implementing a migration mechanism that allows the bridge to accept operations signed under previous handler addresses during a transition period, or establish operational procedures to drain pending operations before handler upgrades.

### [H-02] OwnableDiamond lacks owner initialization, locking diamondCut and bricking upgrades

#### Summary

The OwnableDiamond preset contract inherits from OwnableUpgradeable but fails to provide any mechanism to initialize the owner, leaving it permanently set to the zero address. Since both `diamondCut()` functions are protected by the `onlyOwner` modifier, no caller can satisfy the ownership check, making the diamond proxy completely unusable after deployment. This prevents all facet management operations and initialization logic execution, effectively bricking the contract.

#### Description

The OwnableDiamond contract serves as a preset implementation of the Diamond proxy pattern with ownership-based access control. However, the implementation contains a critical flaw in its initialization design. The contract inherits from OwnableUpgradeable to provide ownership functionality but provides no constructor or external initializer function to set an initial owner.

Upon deployment, the owner remains uninitialized (zero address) while both `diamondCut()` functions require the caller to be the owner through the `onlyOwner` modifier. This creates an impossible condition where no address can satisfy the ownership requirement to call these functions. The `diamondCut()` functions are the sole entry points for adding, replacing, or removing facets, and they also provide the only pathway to execute initialization logic through the `_initializeDiamondCut()` internal function.

The issue manifests deterministically: when OwnableDiamond is deployed as-is, any attempt to call either `diamondCut()` variant will revert because `msg.sender` can never equal the unset owner (zero address). Since these functions are the only mechanism to configure the diamond proxy and execute post-deployment initialization, the contract becomes permanently non-functional.

#### Affected Code

<details>
<summary>

[contracts/presets/diamond/OwnableDiamond.sol:18-34](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/presets/diamond/OwnableDiamond.sol#L18-L34)

</summary>

```solidity
    function diamondCut(Facet[] memory facets_) public onlyOwner {
        diamondCut(facets_, address(0), "");
    }

    /**
     * @notice The function to manipulate the Diamond contract, as defined in [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)
     * @param facets_ the array of actions to be executed against the Diamond
     * @param init_ the address of the init contract to be called via delegatecall
     * @param initData_ the data the init address will be called with
     */
    function diamondCut(
        Facet[] memory facets_,
        address init_,
        bytes memory initData_
    ) public onlyOwner {
        _diamondCut(facets_, init_, initData_);
    }
```
</details>

<details>
<summary>

[contracts/diamond/Diamond.sol:187-204](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/diamond/Diamond.sol#L187-L204)

</summary>

```solidity
    function _initializeDiamondCut(address initFacet_, bytes memory initData_) internal virtual {
        if (initFacet_ == address(0)) {
            return;
        }

        // solhint-disable-next-line
        (bool success_, bytes memory err_) = initFacet_.delegatecall(initData_);

        if (!success_) {
            if (err_.length == 0) revert InitializationReverted(initFacet_, initData_);

            // bubble up error
            // @solidity memory-safe-assembly
            assembly {
                revert(add(32, err_), mload(err_))
            }
        }
    }
```
</details>

#### Impact Explanation

The uninitialized owner creates a permanent denial-of-service condition that renders the diamond proxy entirely unusable. No facets can be added, replaced, or removed through the standard diamond cut operations, preventing the proxy from gaining any functional capabilities. Additionally, no initialization delegatecall can be executed via `_initializeDiamondCut()`, blocking any post-deployment setup logic that would typically establish the contract's intended functionality or set the owner through initialization.

#### Likelihood Explanation

This issue occurs with absolute certainty when deploying the OwnableDiamond preset as provided in the codebase. The owner field remains at the zero address by default, and there exists no alternative pathway within the contract to establish ownership or perform initialization. Every deployment using this preset will result in an immediately non-functional contract unless external modifications are made to the codebase.

#### Recommendation

Consider implementing an initialization mechanism to establish ownership upon deployment. One approach would be to add a constructor that calls `__Ownable_init()` with the deployer's address or a specified owner address, similar to patterns used in other OpenZeppelin upgradeable contract presets. Alternatively, you could provide a public initializer function that sets the owner and can only be called once, following the standard upgradeable proxy initialization pattern.

For a constructor-based approach, you might add:

```solidity
constructor(address initialOwner) {
    __Ownable_init();
    _transferOwnership(initialOwner);
}
```

Alternatively, for an initializer-based approach that follows upgradeable patterns:

```solidity
function initialize(address initialOwner) public initializer {
    __Ownable_init();
    _transferOwnership(initialOwner);
}
```

Either approach would ensure that ownership is properly established, allowing the diamond's core functionality to operate as intended.

### [H-03] Custom hasher function pointers stored in storage are upgrade-unsafe

#### Summary

The Cartesian Merkle Tree and Incremental Merkle Tree libraries store internal function pointers in persistent storage and dereference them during tree operations. This creates a high-severity vulnerability in upgradeable contracts where these function pointers become invalid after implementation upgrades, potentially causing permanent denial of service or incorrect proof verification.

#### Description

The data structures maintain custom hash function pointers directly in contract storage through the `CMT.hash3`, `IMT.hash1`, and `IMT.hash2` fields. These function pointers are set via `setHasher()` methods and subsequently dereferenced in critical operations including proof verification, tree root calculation, and element addition.

In upgradeable deployment contexts such as proxy contracts or diamond patterns, internal function pointers are not stable across implementation upgrades. The encoding of these pointers depends on the deployed bytecode layout, which changes when the contract implementation is upgraded. After an upgrade, the stored function pointers may reference invalid memory locations or unintended code segments.

When tree operations attempt to dereference these invalid pointers, several failure modes can occur. The most likely scenario is a revert due to an invalid jump destination. However, in certain cases, the pointer may reference valid but incorrect code, leading to wrong hash computations and compromised proof verification integrity.

This behavior directly contradicts the library's intended compatibility with upgradeable architectures and can effectively brick deployed systems that have opted into custom hashers.

#### Impact Explanation

The vulnerability can cause permanent denial of service for core tree functionality including proof verification, root calculation, and element insertion. In systems where these trees gate critical operations such as membership verification or authenticated state transitions, this represents a complete breakdown of essential functionality. The impact extends beyond simple unavailability to potential state integrity issues if invalid function pointers execute unintended code that produces incorrect hash values.

#### Likelihood Explanation

The vulnerability materializes when two realistic conditions coincide: deployment of custom hashers through the explicitly supported `setHasher()` functionality, and subsequent implementation upgrades common in proxy and diamond architectures. No additional attacker intervention is required, as routine maintenance upgrades can trigger the issue. Given that custom hashers are actively promoted in the library's documentation and upgradeable deployments are a stated target use case, these conditions represent a probable scenario.

#### Recommendation

Consider redesigning the custom hasher mechanism to avoid storing internal function pointers in persistent storage. One approach could be implementing a registry pattern where custom hashers are identified by immutable identifiers or hashes rather than direct function pointers. The tree could then resolve these identifiers to the appropriate hash functions at runtime, ensuring compatibility across upgrades.

Alternatively, consider implementing validation logic that detects invalid function pointers and gracefully falls back to default hash functions, though this approach may not fully address the root cause. For immediate mitigation, consider documenting the upgrade incompatibility and providing clear migration paths for systems that need to change hash functions after upgrades.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:630-638](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L630-L638)

</summary>

```solidity
    struct CMT {
        mapping(uint64 => Node) nodes;
        uint64 merkleRootId;
        uint64 nodesCount;
        uint64 deletedNodesCount;
        uint32 desiredProofSize;
        bool isCustomHasherSet;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:700-709](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L700-L709)

</summary>

```solidity
    function _setHasher(
        CMT storage treaple,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        if (_nodesCount(treaple) != 0) revert TreapleNotEmpty();

        treaple.isCustomHasherSet = true;

        treaple.hash3 = hash3_;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:942-947](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L942-L947)

</summary>

```solidity
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
            .isCustomHasherSet
            ? treaple.hash3
            : _hash3;

        return _processProof(hash3_, proof_) == proof_.root;
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:1062-1067](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L1062-L1067)

</summary>

```solidity
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
            .isCustomHasherSet
            ? treaple.hash3
            : _hash3;

        return hash3_(nodeKey_, leftNodeKey_, rightNodeKey_);
```
</details>

<details>
<summary>

[contracts/libs/data-structures/IncrementalMerkleTree.sol:380-387](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/IncrementalMerkleTree.sol#L380-L387)

</summary>

```solidity
    struct IMT {
        bytes32[] branches;
        uint256 leavesCount;
        bool isStrictHeightSet;
        bool isCustomHasherSet;
        function(bytes32) view returns (bytes32) hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/IncrementalMerkleTree.sol:415-420](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/IncrementalMerkleTree.sol#L415-L420)

</summary>

```solidity
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
```
</details>

<details>
<summary>

[contracts/libs/data-structures/IncrementalMerkleTree.sol:450-455](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/IncrementalMerkleTree.sol#L450-L455)

</summary>

```solidity
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
```
</details>

<details>
<summary>

[contracts/libs/data-structures/IncrementalMerkleTree.sol:493-496](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/IncrementalMerkleTree.sol#L493-L496)

</summary>

```solidity
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
```
</details>

<details>
<summary>

[contracts/libs/data-structures/IncrementalMerkleTree.sol:531-536](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/IncrementalMerkleTree.sol#L531-L536)

</summary>

```solidity
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
```
</details>


### [H-04] PriorityQueue.remove breaks heap invariant due to missing upward reheapification

#### Summary

The PriorityQueue library's `remove(value)` function violates the max-heap invariant by only performing downward reheapification after replacing a removed element with the last element. This vulnerability can lead to incorrect priority ordering in applications relying on the queue for critical decision-making processes.

#### Description

The PriorityQueue library implements a max-heap data structure where the element with the highest priority is maintained at the root. When removing an arbitrary element by value, the implementation replaces the removed element with the last element in the heap and then only calls `_shiftDown()` to maintain heap properties.

The critical flaw occurs when the replacement element has a higher priority than its new parent. In a proper max-heap, parent priorities must be greater than or equal to their children's priorities. The current implementation only checks if the replacement element needs to move down (comparing with children) but never checks if it should move up (comparing with its parent).

When the heap invariant is violated, subsequent operations like `top()`, `removeTop()`, and `values()` may operate on a corrupted heap state. The maximum element may no longer be at the root position, causing these functions to return incorrect results and process elements in the wrong order.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/PriorityQueue.sol:304-340](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/PriorityQueue.sol#L304-L340)

</summary>

```solidity
    function _remove(Queue storage queue, bytes32 value_) private returns (bool) {
        uint256 length_ = _length(queue);

        if (length_ == 0) {
            return false;
        }

        uint256 indexToRemove_ = type(uint256).max;

        for (uint256 i = 0; i < length_; ++i) {
            if (queue._values[i] == value_) {
                indexToRemove_ = i;
                break;
            }
        }

        if (indexToRemove_ == type(uint256).max) {
            return false;
        }

        if (indexToRemove_ == length_ - 1) {
            queue._values.pop();
            queue._priorities.pop();

            return true;
        }

        queue._values[indexToRemove_] = queue._values[length_ - 1];
        queue._priorities[indexToRemove_] = queue._priorities[length_ - 1];

        queue._values.pop();
        queue._priorities.pop();

        _shiftDown(queue, indexToRemove_);

        return true;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/PriorityQueue.sol:380-392](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/PriorityQueue.sol#L380-L392)

</summary>

```solidity
    function _shiftDown(Queue storage queue, uint256 index_) private {
        while (true) {
            uint256 maxIndex_ = _maxPriorityIndex(queue, index_);

            if (index_ == maxIndex_) {
                break;
            }

            _swap(queue, maxIndex_, index_);

            index_ = maxIndex_;
        }
    }
```
</details>

#### Impact Explanation

The heap invariant violation can cause consumers depending on strict max-priority behavior to make incorrect decisions. Applications using the priority queue for task scheduling, order matching, liquidation processing, or access control may select suboptimal elements instead of the true maximum priority items. This can lead to starvation of high-priority operations and material logic integrity violations that affect protocol behavior, though the library itself does not directly handle funds.

#### Likelihood Explanation

The issue manifests deterministically whenever `remove(value)` replaces a node with a higher-priority element whose priority exceeds its new parent's priority. Users can readily construct such conditions by controlling element insertions and strategically invoking removals on non-last elements. If consumers expose the `remove(value)` functionality or use it internally, this condition occurs commonly during normal usage patterns.

#### Recommendation

Consider implementing proper bidirectional reheapification in the `_remove()` function. After replacing the removed element with the last element, the implementation should check both upward and downward heap violations.

One approach could be to add a `_shiftUp()` function that compares an element with its parent and bubbles it upward when necessary. The removal logic should then determine whether to call `_shiftDown()` or `_shiftUp()` based on comparing the replacement element's priority with its parent and children.

The remediation strategy would involve:
1. Implementing a `_shiftUp()` function that performs upward reheapification
2. Modifying the `_remove()` function to check if upward movement is needed before defaulting to downward movement
3. Ensuring that after any replacement operation, the heap property is fully restored in both directions

This enhancement would ensure that the max-heap invariant is maintained regardless of the relative priorities of the replacement element and its new neighbors.

## Medium Findings

### [M-01] Deterministic treap priorities allow adversarial worst-case height causing gas DoS

#### Summary

The CartesianMerkleTree implementation uses deterministic priorities derived from node keys (`keccak256(key)`), enabling adversaries to craft key sequences that degenerate the treap into a linear structure. This transforms expected O(log n) operations into O(n) complexity, potentially causing out-of-gas failures and denial of service for dependent features. The vulnerability is rated Medium severity due to the significant operational impact under realistic adversarial conditions.

#### Description

The CartesianMerkleTree implements a treap data structure where node priorities are deterministically calculated as `bytes16(keccak256(key))` as documented in the Node struct. The treap maintains its heap property through rotations that compare these priorities during insertion and removal operations.

An adversary can exploit this deterministic design by selecting keys whose derived priorities form a strictly increasing sequence. When such keys are inserted in ascending order, the treap's rotation logic causes each new node to bubble toward the root, creating a highly unbalanced tree with near-linear height rather than the expected logarithmic structure.

The vulnerability manifests in the `_add()` function's recursive insertion logic, where priority comparisons trigger rotations to maintain the heap property. Similarly, operations like `_remove()` and `_proof()` traverse the tree depth recursively, making their gas consumption proportional to tree height. When an adversary degrades the treap to linear height through carefully chosen keys, these operations scale from O(log n) to O(n) complexity.

Key insertion occurs through recursive calls in `_add()`, where left and right rotations are performed based on priority comparisons between parent and child nodes. The deterministic nature of priority calculation allows attackers to precompute key sequences that will reliably produce worst-case tree shapes through offline grinding.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:652-658](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L652-L658)

</summary>

```solidity
    struct Node {
        uint64 childLeft;
        uint64 childRight;
        bytes16 priority;
        bytes32 merkleHash;
        bytes32 key;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:723-755](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L723-L755)

</summary>

```solidity
    function _add(
        CMT storage treaple,
        uint256 rootNodeId_,
        bytes32 key_
    ) private returns (uint256) {
        Node storage rootNode = treaple.nodes[uint64(rootNodeId_)];

        if (rootNode.key == 0) {
            return _newNode(treaple, key_);
        }

        if (rootNode.key == key_) revert KeyAlreadyExists();

        if (rootNode.key > key_) {
            rootNode.childLeft = uint64(_add(treaple, rootNode.childLeft, key_));

            if (treaple.nodes[rootNode.childLeft].priority > rootNode.priority) {
                rootNodeId_ = _rightRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];
            }
        } else {
            rootNode.childRight = uint64(_add(treaple, rootNode.childRight, key_));

            if (treaple.nodes[rootNode.childRight].priority > rootNode.priority) {
                rootNodeId_ = _leftRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];
            }
        }

        rootNode.merkleHash = _hashNodes(treaple, rootNodeId_);

        return rootNodeId_;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:757-801](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L757-L801)

</summary>

```solidity
    function _remove(
        CMT storage treaple,
        uint256 rootNodeId_,
        bytes32 key_
    ) private returns (uint256) {
        Node storage rootNode = treaple.nodes[uint64(rootNodeId_)];

        if (rootNode.key == 0) revert NodeDoesNotExist();

        if (key_ < rootNode.key) {
            rootNode.childLeft = uint64(_remove(treaple, rootNode.childLeft, key_));
        } else if (key_ > rootNode.key) {
            rootNode.childRight = uint64(_remove(treaple, rootNode.childRight, key_));
        }

        if (rootNode.key == key_) {
            Node storage leftRootChildNode = treaple.nodes[rootNode.childLeft];
            Node storage rightRootChildNode = treaple.nodes[rootNode.childRight];

            if (leftRootChildNode.key == 0 || rightRootChildNode.key == 0) {
                uint64 nodeIdToRemove_ = uint64(rootNodeId_);

                rootNodeId_ = leftRootChildNode.key == 0
                    ? rootNode.childRight
                    : rootNode.childLeft;

                ++treaple.deletedNodesCount;
                delete treaple.nodes[nodeIdToRemove_];
            } else if (leftRootChildNode.priority < rightRootChildNode.priority) {
                rootNodeId_ = _leftRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];

                rootNode.childLeft = uint64(_remove(treaple, rootNode.childLeft, key_));
            } else {
                rootNodeId_ = _rightRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];

                rootNode.childRight = uint64(_remove(treaple, rootNode.childRight, key_));
            }
        }

        rootNode.merkleHash = _hashNodes(treaple, rootNodeId_);

        return rootNodeId_;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:865-933](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L865-L933)

</summary>

```solidity
        while (true) {
            node = treaple.nodes[uint64(nextNodeId_)];

            if (node.key == key_) {
                bytes32 leftHash_ = treaple.nodes[node.childLeft].merkleHash;
                bytes32 rightHash_ = treaple.nodes[node.childRight].merkleHash;

                _addProofSibling(proof_, currentSiblingsIndex_++, leftHash_);
                _addProofSibling(proof_, currentSiblingsIndex_++, rightHash_);

                proof_.directionBits = _calculateDirectionBit(
                    directionBits_,
                    currentSiblingsIndex_,
                    leftHash_,
                    rightHash_
                );

                proof_.existence = true;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            uint64 otherNodeId_;

            if (node.key > key_) {
                otherNodeId_ = node.childRight;
                nextNodeId_ = node.childLeft;
            } else {
                otherNodeId_ = node.childLeft;
                nextNodeId_ = node.childRight;
            }

            if (nextNodeId_ == 0) {
                bytes32 leftHash_ = treaple.nodes[node.childLeft].merkleHash;
                bytes32 rightHash_ = treaple.nodes[node.childRight].merkleHash;

                _addProofSibling(proof_, currentSiblingsIndex_++, leftHash_);
                _addProofSibling(proof_, currentSiblingsIndex_++, rightHash_);

                proof_.directionBits = _calculateDirectionBit(
                    directionBits_,
                    currentSiblingsIndex_,
                    leftHash_,
                    rightHash_
                );

                proof_.nonExistenceKey = node.key;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            _addProofSibling(proof_, currentSiblingsIndex_++, node.key);
            _addProofSibling(
                proof_,
                currentSiblingsIndex_++,
                treaple.nodes[otherNodeId_].merkleHash
            );

            directionBits_ = _calculateDirectionBit(
                directionBits_,
                currentSiblingsIndex_,
                treaple.nodes[uint64(nextNodeId_)].merkleHash,
                treaple.nodes[otherNodeId_].merkleHash
            );
        }

        return proof_;
```
</details>

#### Impact Explanation

The treap's deterministic priority system enables adversaries to craft key sequences that degenerate the structure into a linear tree. Core operations including add, remove, and proof generation then scale with tree height rather than maintaining logarithmic complexity. This results in exponential gas consumption increases that can trigger out-of-gas reverts, effectively denying service to features dependent on the CartesianMerkleTree. While no funds are directly at risk, the availability impact can severely disrupt protocol functionality that relies on efficient tree operations.

#### Likelihood Explanation

For implementations using UintCMT or Bytes32CMT where users control key selection, generating adversarial key sequences requires minimal computational effort through offline grinding of hash values. Many realistic integrations expose untrusted key insertion patterns, such as user-supplied identifiers or transaction-derived keys. The deterministic priority calculation makes this attack practical and reproducible across different contexts where the library may be deployed.

#### Recommendation

Consider implementing non-deterministic priority generation to prevent adversarial manipulation of tree structure. One approach would be to incorporate a deployment-time or contract-specific salt into the priority calculation, making it infeasible for attackers to predict priority relationships between keys.

Another strategy involves implementing tree rebalancing mechanisms or maximum depth limits that trigger defensive actions when the tree becomes severely unbalanced. This could include periodic restructuring or alternative data structure fallbacks for degraded cases.

For applications with trusted key sources, access control mechanisms can limit who may insert keys, reducing the attack surface. However, for general-purpose library usage where key control may vary across implementations, the underlying deterministic design remains a concern that should be addressed at the library level.

## Low Findings

### [L-01] CartesianMerkleTree.verifyProof can revert on malformed proofs due to missing siblings-length validation

#### Summary

The `verifyProof()` function in the Cartesian Merkle Tree implementation may revert unexpectedly when processing malformed proofs with insufficient sibling data. This behavior occurs when an attacker provides a proof with `existence == false`, a non-zero `nonExistenceKey`, but `siblingsLength < 2`, causing out-of-bounds array access during proof processing. The issue affects consumers that expect boolean outcomes for invalid proofs, potentially enabling denial-of-service attacks on functions that verify untrusted proof data.

#### Description

The vulnerability stems from insufficient validation in the proof verification process. The `_verifyProof()` function at lines 936-948 performs a limited validation check that only catches the specific case where `existence == false` and `nonExistenceKey == ZERO_HASH`. However, it does not validate that the siblings array contains the minimum required elements before calling `_processProof()`.

The `_processProof()` function at lines 950-987 immediately accesses `siblings[siblingsLength-2]` and `siblings[siblingsLength-1]` without verifying that `siblingsLength >= 2`. When `siblingsLength` is 0 or 1, these array accesses result in out-of-bounds reads that cause the transaction to revert.

An attacker can exploit this by crafting a malformed proof with:
- `existence = false`
- `nonExistenceKey != 0` (bypassing the early validation)
- `siblingsLength = 0` or `1` with a correspondingly short siblings array

When such a proof is processed, the function reverts instead of returning false, disrupting any consumer logic that relies on graceful handling of invalid proofs.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:936-948](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L936-L948)

</summary>

```solidity
    function _verifyProof(CMT storage treaple, Proof memory proof_) private view returns (bool) {
        // invalid exclusion proof
        if (!proof_.existence && proof_.nonExistenceKey == ZERO_HASH) {
            return false;
        }

        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
            .isCustomHasherSet
            ? treaple.hash3
            : _hash3;

        return _processProof(hash3_, proof_) == proof_.root;
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/CartesianMerkleTree.sol:950-987](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/CartesianMerkleTree.sol#L950-L987)

</summary>

```solidity
    function _processProof(
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_,
        Proof memory proof_
    ) private view returns (bytes32) {
        bool directionBit_ = _extractDirectionBit(proof_.directionBits, 0);

        bytes32 leftHash_ = proof_.siblings[proof_.siblingsLength - 2];
        bytes32 rightHash_ = proof_.siblings[proof_.siblingsLength - 1];

        if (directionBit_) {
            (leftHash_, rightHash_) = (rightHash_, leftHash_);
        }

        bytes32 computedHash_ = hash3_(
            proof_.existence ? proof_.key : proof_.nonExistenceKey,
            leftHash_,
            rightHash_
        );

        for (uint256 i = 2; i < proof_.siblingsLength; i += 2) {
            directionBit_ = _extractDirectionBit(proof_.directionBits, i);

            leftHash_ = computedHash_;
            rightHash_ = proof_.siblings[proof_.siblingsLength - i - 1];

            if (directionBit_) {
                (leftHash_, rightHash_) = (rightHash_, leftHash_);
            }

            computedHash_ = hash3_(
                proof_.siblings[proof_.siblingsLength - i - 2],
                leftHash_,
                rightHash_
            );
        }

        return computedHash_;
    }
```
</details>

#### Impact Explanation

The vulnerability can cause unexpected reverts during proof verification, blocking user operations or halting batch processing where invalid proofs should be handled gracefully. While this does not result in direct asset loss, it can deny execution of legitimate functions that incorporate proof verification as part of their workflow. The impact is particularly relevant for systems that process multiple proofs in batches or use proof verification as a gating mechanism for critical operations.

#### Likelihood Explanation

An attacker can easily craft malformed proofs with the required characteristics if a consumer system verifies untrusted proof data. The likelihood depends on whether consumers implement proof verification in contexts where such denial-of-service would be meaningful beyond the attacker's own transaction. This scenario is plausible in systems that use batched verification or where proof validation is part of control flow that expects non-reverting behavior for invalid inputs.

#### Recommendation

Consider adding validation to ensure the siblings array contains sufficient elements before processing. One approach could be to add a length check in `_verifyProof()` before calling `_processProof()`:

```diff
function _verifyProof(CMT storage treaple, Proof memory proof_) private view returns (bool) {
    // invalid exclusion proof
    if (!proof_.existence && proof_.nonExistenceKey == ZERO_HASH) {
        return false;
    }

+   // ensure minimum proof length for processing
+   if (proof_.siblingsLength < 2) {
+       return false;
+   }

    function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
        .isCustomHasherSet
        ? treaple.hash3
        : _hash3;

    return _processProof(hash3_, proof_) == proof_.root;
}
```

This validation ensures that malformed proofs with insufficient sibling data are rejected gracefully with a false return value rather than causing unexpected reverts, maintaining the expected boolean semantics for proof verification operations.

### [L-02] U512.modsub returns m instead of 0 when a ≡ b (mod m) in negative branch

#### Summary

The `_modsub()` function in the U512 library contains a correctness bug that violates canonical modular reduction. When computing (a - b) mod m where a ≡ b (mod m) and a < b, the function returns m instead of the expected 0, producing a non-reduced result outside the range [0, m-1]. While current cryptographic modules use `_redsub()` instead of `_modsub()`, this primitive flaw may affect integrators relying on the function for security-critical mathematics.

#### Description

The internal `_modsub()` function implements modular subtraction by computing the absolute difference |a - b|, reducing it modulo m via the modexp precompile, and applying post-processing when a < b. The implementation contains a logic error in the negative branch handling:

When a < b, the function:
1. Computes |a - b| = b - a
2. Reduces this value modulo m using the precompile
3. If the reduction yields 0 (when b - a is a multiple of m), applies r = m - 0 = m

This final step produces r = m, which lies outside the canonical range [0, m-1] and violates the function's documented contract of computing "(a_ - b_) % m_". The bug occurs deterministically when a ≡ b (mod m) and a < b, such as when a = 5, b = 10, m = 5.

The root cause is missing final reduction after the post-processing step, combined with not handling the special case where the precompile reduction yields zero.

#### Affected Code

<details>
<summary>

[contracts/libs/bn/U512.sol:1541-1567](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/bn/U512.sol#L1541-L1567)

</summary>

```solidity
    function _modsub(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            int256 cmp_ = cmp(a_, b_);

            if (cmp_ >= 0) {
                _sub(a_, b_, r_);
            } else {
                _sub(b_, a_, r_);
            }

            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(r_))
                mstore(add(call_, 0x80), mload(add(r_, 0x20)))
                mstore(add(call_, 0xA0), 0x01)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            if (cmp_ < 0) {
                _sub(m_, r_, r_);
            }
        }
```
</details>

#### Impact Explanation

This bug violates fundamental modular arithmetic guarantees by returning values outside the canonical field range. Such non-reduced elements can corrupt downstream cryptographic operations that assume inputs are properly reduced, potentially leading to incorrect elliptic curve computations, field element comparisons, or verification logic. The impact materializes when integrators use `_modsub()` in security-critical contexts where canonical reduction is essential for correctness.

#### Likelihood Explanation

The erroneous condition triggers deterministically when a ≡ b (mod m) and a < b, which can occur in typical field arithmetic scenarios. However, the current codebase mitigates this risk by using `_redsub()` instead of `_modsub()` in cryptographic modules like ECDSA384/512. Exploitation requires external consumers to directly invoke `_modsub()` in sensitive mathematical operations.

#### Recommendation

Consider adding a final reduction step to ensure the result always lies within the canonical range [0, m-1]. One approach could be to check if the post-processed result equals m and reduce it to 0:

```diff
if (cmp_ < 0) {
    _sub(m_, r_, r_);
+   if (eq(r_, m_)) {
+       assembly {
+           mstore(r_, 0)
+           mstore(add(r_, 0x20), 0)
+       }
+   }
}
```

Alternatively, consider implementing a more robust approach that unconditionally applies modular reduction after the post-processing step to guarantee canonical results. This would prevent similar edge cases and ensure the function consistently meets its documented contract regardless of input relationships.

### [L-03] RSA-PSS maskedDB top-bit check is incorrect, allowing non-compliant encodings to pass verification

#### Summary

The RSA-PSS signature verifier contains an incorrect bit mask check that fails to properly validate the leftmost bits of maskedDB according to RFC 8017. This low-severity issue may allow non-compliant PSS encodings to pass verification, potentially causing cross-implementation inconsistency between this library and standards-compliant verifiers.

#### Description

The RSA-PSS verification implementation in `_pss()` contains a logical error when checking the required zero bits in maskedDB. According to RFC 8017, the leftmost (8*emLen − emBits) bits of maskedDB must be zero. However, the current implementation incorrectly uses an equality check against 1 instead of checking for any non-zero bits.

At line 138, the code performs:
```solidity
if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
    return false;
}
```

This check only rejects maskedDB when the masked high bits equal exactly 1, but fails to reject other non-zero bit patterns. The condition should verify that no high bits are set (i.e., the result equals 0).

Additionally, after the MGF1 unmasking process (lines 144-146), the implementation forcibly clears the leftmost bits of DB at lines 148-150 without first verifying that maskedDB originally satisfied the zero-bit constraint. This further relaxes the validation beyond the PSS specification requirements.

The vulnerability affects the core PSS encoding validation in the `_pss()` function, which is called by both `verify()` and `verifySha256()` methods that applications rely on for RSA-PSS signature verification.

#### Affected Code

<details>
<summary>

[contracts/libs/crypto/RSASSAPSS.sol:102-151](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/crypto/RSASSAPSS.sol#L102-L151)

</summary>

```solidity
     * @notice Checks the PSS encoding.
     */
    function _pss(
        bytes memory message_,
        bytes memory signature_,
        Parameters memory params_
    ) private pure returns (bool) {
        unchecked {
            uint256 hashLength_ = params_.hashLength;
            uint256 saltLength_ = params_.saltLength;
            uint256 sigBytes_ = signature_.length;
            uint256 sigBits_ = (sigBytes_ * 8 - 1) & 7;

            assert(message_.length < 2 ** 61);

            bytes memory messageHash_ = params_.hasher(message_);

            if (sigBytes_ < hashLength_ + saltLength_ + 2) {
                return false;
            }

            if (signature_[sigBytes_ - 1] != hex"BC") {
                return false;
            }

            bytes memory db_ = new bytes(sigBytes_ - hashLength_ - 1);
            bytes memory h_ = new bytes(hashLength_);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] = signature_[i];
            }

            for (uint256 i = 0; i < hashLength_; ++i) {
                h_[i] = signature_[i + db_.length];
            }

            if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
                return false;
            }

            bytes memory dbMask_ = _mgf(params_, h_, db_.length);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] ^= dbMask_[i];
            }

            if (sigBits_ > 0) {
                db_[0] &= bytes1(uint8(0xFF >> (8 - sigBits_)));
            }
```
</details>

#### Impact Explanation

The incorrect check allows PSS encodings with non-zero leftmost bits in maskedDB to pass verification when they should be rejected per RFC 8017. This creates potential for cross-implementation inconsistency, where this library accepts signatures that compliant verifiers would reject. While direct fund loss or privilege escalation remains unlikely due to the computational infeasibility of forging RSA signatures without the private key, the standards non-compliance may enable authorization bypass in scenarios where applications assume all verifiers behave identically.

#### Likelihood Explanation

Practical exploitation requires crafting a signature value where the decoded message has non-zero maskedDB high bits while satisfying all other PSS validation checks. Without access to the private key, producing such a signature remains computationally infeasible under standard RSA assumptions. The vulnerability represents a clear correctness bug, but the likelihood of successful exploitation in real-world scenarios is very low.

#### Recommendation

Consider correcting the maskedDB validation logic to properly enforce the RFC 8017 requirement. The fix should replace the equality check with a proper zero-bit validation:

```diff
- if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
+ if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) != 0) {
    return false;
}
```

Additionally, consider removing the post-unmasking bit clearing at lines 148-150, as the maskedDB constraint should be validated before unmasking rather than silently corrected afterward. This approach would align the implementation with the PSS specification and ensure consistent behavior across different RSA-PSS verifiers.

### [L-04] Bitcoin TxParser rejects versions >2, causing txid calculation revert and DoS for BTC inclusion verification

#### Summary

The Bitcoin transaction parser enforces a restrictive version check that only accepts versions 1 or 2, causing hard reverts for valid Bitcoin transactions with higher versions. This limitation affects transaction ID calculation and blocks inclusion verification workflows, creating a potential denial of service for systems relying on this library.

#### Description

The `TxParser.parseTransaction()` function implements a strict version validation that rejects any transaction with a version other than 1 or 2. This occurs at lines 76-78 in `TxParser.sol`, where the parser checks `if (tx_.version != 1 && tx_.version != 2)` and reverts with `UnsupportedVersion(tx_.version)` for any other values.

This restriction cascades through critical library functions. The `calculateTxId()` function depends on `_removeWitness()`, which in turn calls `parseTransaction()`. When attempting to compute a transaction ID for a valid Bitcoin transaction with version 3 or higher, the entire operation fails due to the version check.

The issue also affects the `isTransaction()` function used by `TxMerkleProof` for insertion attack detection. At lines 225-229, this function performs a similar version restriction, only recognizing versions 1-2 as valid transactions. While Bitcoin consensus rules do not strictly limit transaction versions to these values, the parser's implementation creates an artificial constraint that can block legitimate Bitcoin transactions from being processed on-chain.

#### Affected Code

<details>
<summary>

[contracts/libs/bitcoin/TxParser.sol:76-78](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/bitcoin/TxParser.sol#L76-L78)

</summary>

```solidity
        if (tx_.version != 1 && tx_.version != 2) {
            revert UnsupportedVersion(tx_.version);
        }
```
</details>

<details>
<summary>

[contracts/libs/bitcoin/TxParser.sol:46-48](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/bitcoin/TxParser.sol#L46-L48)

</summary>

```solidity
    function calculateTxId(bytes calldata data_) internal pure returns (bytes32) {
        return _doubleSHA256(_removeWitness(data_));
    }
```
</details>

<details>
<summary>

[contracts/libs/bitcoin/TxParser.sol:480-487](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/bitcoin/TxParser.sol#L480-L487)

</summary>

```solidity
     * @notice Remove witness from a raw transaction
     */
    function _removeWitness(bytes calldata data_) private pure returns (bytes memory) {
        (TxParser.Transaction memory tx_, ) = parseTransaction(data_);

        if (tx_.hasWitness) {
            return formatTransaction(tx_, false);
        }
```
</details>

<details>
<summary>

[contracts/libs/bitcoin/TxParser.sol:219-235](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/bitcoin/TxParser.sol#L219-L235)

</summary>

```solidity
    function isTransaction(bytes memory data_) internal pure returns (bool) {
        if (data_.length < 60) {
            return false;
        }

        {
            uint256 version_ = uint8(bytes1(data_[0]));

            if (version_ < 1 || version_ > 2) {
                return false;
            }
        }

        if (bytes1(data_[1]) != bytes1(0)) return false;
        if (bytes1(data_[2]) != bytes1(0)) return false;
        if (bytes1(data_[3]) != bytes1(0)) return false;
```
</details>

#### Impact Explanation

The restriction creates a denial of service condition where systems using this library cannot verify Bitcoin transaction inclusion for transactions with versions greater than 2. Since `calculateTxId()` is fundamental to transaction verification workflows, any attempt to process higher-version transactions results in a hard revert, preventing expected protocol operations such as cross-chain redemptions or message acceptance. While no funds are directly at risk, the liveness impact can halt critical system functionality when such transactions are encountered.

#### Likelihood Explanation

Bitcoin consensus permits higher transaction versions, and while currently uncommon due to mempool policies, miners can include such transactions in blocks. An attacker could intentionally create higher-version transactions to trigger this denial of service, requiring only the ability to craft such transactions and have them mined. The feasibility of this attack vector, combined with potential future adoption of higher transaction versions, makes this a realistic concern for systems relying on this library.

#### Recommendation

Consider relaxing the version restriction to align with Bitcoin consensus rules rather than enforcing specific version values. One approach could be to modify the version validation to accept a broader range of versions or remove the strict version check entirely, since Bitcoin's consensus layer already handles version validation.

For the `parseTransaction()` function, the version check could be updated to allow any reasonable version number, or the validation could be made configurable to accommodate future Bitcoin protocol changes. Similarly, the `isTransaction()` function should be updated to recognize higher-version transactions to maintain its effectiveness as a defense mechanism.

The remediation should ensure that the library remains compatible with current Bitcoin transactions while providing flexibility for future protocol evolution, preventing similar issues when new transaction versions are introduced.

### [L-05] RSASSA-PSS leading-bits check is ineffective and sigBits computed incorrectly

#### Summary

The RSA-PSS signature verification implementation contains an ineffective leading-bits validation check that compares against the incorrect value and derives sigBits from signature length rather than modulus bit length. This represents a Low severity standards compliance issue that may accept malformed encodings violating EMSA-PSS requirements.

#### Description

The PSS decoder in `_pss()` performs an incorrect validation of the most significant bits in the masked data block (maskedDB). The implementation exhibits two key deviations from the EMSA-PSS standard:

First, the leading-bits check at line 138 compares the masked bits against the value 1 instead of verifying they are zero. The condition `uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1` will almost never trigger because the masked result can only be 0x00 or 0x80, not 0x01. This renders the intended constraint check ineffective.

Second, the computation of `sigBits_` at line 113 derives the value from the signature byte length using `(sigBytes_ * 8 - 1) & 7` rather than the RSA modulus bit length. This calculation produces an incorrect bit offset that is applied to the wrong data buffer during validation.

The code subsequently clears the top bits unconditionally at lines 148-150 without verifying they were originally zero, which masks potentially invalid encodings that should be rejected according to EMSA-PSS decoding rules. When combined with the ineffective bit check, this allows the verifier to accept encodings that would not be produced by a compliant PSS encoder.

#### Impact Explanation

The verifier accepts EMSA-PSS encodings with the maskedDB's most significant bit set, violating the standard. This creates a standards compliance issue that can cause cross-implementation acceptance discrepancies between this verifier and compliant implementations. While this does not directly enable signature forgery without breaking the underlying RSA problem, it represents a leniency that deviates from specification requirements and may affect interoperability in multi-verifier environments.

#### Likelihood Explanation

Exploiting this flaw to gain unauthorized signature acceptance would require producing a signature whose RSA-deciphered block has invalid leading bits but still satisfies all other PSS validation checks, without knowledge of the private key. This effectively reduces to forging RSA-PSS signatures, which remains computationally infeasible under standard cryptographic assumptions. While the standards deviation is certain to occur, realistic exploitation for unauthorized access or privilege escalation is highly unlikely.

#### Recommendation

Consider correcting the leading-bits validation to ensure strict EMSA-PSS compliance. The remediation should address both the bit check logic and the sigBits computation:

For the bit validation, modify the check to verify that the masked leading bits are zero rather than comparing against 1. The condition should validate that `(maskedDB[0] & mask) == 0` where the mask is derived from the correct bit offset.

For the sigBits calculation, derive the value from the RSA modulus bit length rather than the signature byte length. The proper computation should be `sigBits = (modulusBitLength - 1) % 8` to determine how many leading bits in the first octet should be zero.

Additionally, ensure that the bit clearing operation only occurs after successful validation of the original bit state, rather than unconditionally masking potentially invalid encodings. This approach maintains the verification's soundness while ensuring interoperability with other compliant RSASSA-PSS implementations.

#### Affected Code

<details>
<summary>

[contracts/libs/crypto/RSASSAPSS.sol:104-151](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/crypto/RSASSAPSS.sol#L104-L151)

</summary>

```solidity
    function _pss(
        bytes memory message_,
        bytes memory signature_,
        Parameters memory params_
    ) private pure returns (bool) {
        unchecked {
            uint256 hashLength_ = params_.hashLength;
            uint256 saltLength_ = params_.saltLength;
            uint256 sigBytes_ = signature_.length;
            uint256 sigBits_ = (sigBytes_ * 8 - 1) & 7;

            assert(message_.length < 2 ** 61);

            bytes memory messageHash_ = params_.hasher(message_);

            if (sigBytes_ < hashLength_ + saltLength_ + 2) {
                return false;
            }

            if (signature_[sigBytes_ - 1] != hex"BC") {
                return false;
            }

            bytes memory db_ = new bytes(sigBytes_ - hashLength_ - 1);
            bytes memory h_ = new bytes(hashLength_);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] = signature_[i];
            }

            for (uint256 i = 0; i < hashLength_; ++i) {
                h_[i] = signature_[i + db_.length];
            }

            if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
                return false;
            }

            bytes memory dbMask_ = _mgf(params_, h_, db_.length);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] ^= dbMask_[i];
            }

            if (sigBits_ > 0) {
                db_[0] &= bytes1(uint8(0xFF >> (8 - sigBits_)));
            }
```
</details>


### [L-06] Vector memory arithmetic overflows enable in-call memory corruption and DoS for huge lengths

#### Summary

The Vector library contains unchecked assembly arithmetic in allocation and resizing operations that can cause memory corruption and denial of service when extremely large lengths are used. This Low severity vulnerability allows creation of vectors with massive logical lengths without proper memory allocation, enabling writes to unintended memory locations and potential corruption of return data within the same transaction call.

#### Description

The Vector library's memory management functions contain several unchecked arithmetic operations that can overflow with extremely large input values. The primary concern lies in the assembly code within `_allocate()` and `_resize()` functions, where multiplication and addition operations on user-controlled lengths can wrap around without validation.

In `_allocate()`, the free memory pointer is updated using `mul(allocation_, 0x20)` without overflow checks. When `allocation_` is extremely large, this multiplication can overflow, causing the memory pointer to advance by an incorrect amount or wrap to a small value. Similarly, in `_resize()`, the copy loop bound calculation `add(mul(length_, 0x20), 0x20)` can overflow, potentially skipping necessary memory copies or accessing incorrect memory regions.

While the Solidity compiler's overflow protection in version 0.8+ prevents `length_ + 1` from wrapping in `_new(uint256 length_)`, the unchecked assembly operations in allocation and resizing remain vulnerable. When combined with very large allocation sizes, these arithmetic overflows can create vectors that appear to have massive logical lengths but lack corresponding allocated memory.

This condition enables several problematic scenarios: bounds checks may pass due to the large logical length while actual memory writes occur at incorrect locations, potentially overwriting ABI-encoded return buffers or other memory structures. The corruption can manifest as malformed return data, unexpected reverts during ABI encoding, or denial of service when the system attempts to process impossibly large array lengths.

#### Affected Code

<details>
<summary>

[contracts/libs/data-structures/memory/Vector.sol:326-338](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/memory/Vector.sol#L326-L338)

</summary>

```solidity
    function _new(uint256 length_) private pure returns (Vector memory vector) {
        uint256 allocation_ = length_ + 1;
        uint256 dataPointer_ = _allocate(allocation_);

        _clean(dataPointer_, allocation_);

        vector._allocation = allocation_;
        vector._dataPointer = dataPointer_;

        assembly {
            mstore(dataPointer_, length_)
        }
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/memory/Vector.sol:408-426](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/memory/Vector.sol#L408-L426)

</summary>

```solidity
    function _resize(Vector memory vector, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(vector, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(vector, newAllocation_)
            mstore(add(vector, 0x20), newDataPointer_)
        }
    }
```
</details>

<details>
<summary>

[contracts/libs/data-structures/memory/Vector.sol:444-448](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/data-structures/memory/Vector.sol#L444-L448)

</summary>

```solidity
    function _allocate(uint256 allocation_) private pure returns (uint256 pointer_) {
        assembly {
            pointer_ := mload(0x40)
            mstore(0x40, add(pointer_, mul(allocation_, 0x20)))
        }
```
</details>

<details>
<summary>

[vector-backup/contracts/libs/data-structures/memory/Vector.sol:408-426](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/vector-backup/contracts/libs/data-structures/memory/Vector.sol#L408-L426)

</summary>

```solidity
    function _resize(Vector memory vector, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(vector, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(vector, newAllocation_)
            mstore(add(vector, 0x20), newDataPointer_)
        }
    }
```
</details>

#### Impact Explanation

The vulnerability enables in-call memory corruption that can affect transaction correctness and availability. Unchecked assembly arithmetic on capacities and lengths allows creating vectors with extremely large logical lengths without properly reserving corresponding memory. Subsequent operations can write to unintended memory locations, potentially corrupting ABI-encoded return data or causing reverts due to malformed array structures. While this affects the reliability of individual transaction calls and can cause denial of service, it does not directly threaten on-chain asset security or enable persistent state corruption.

#### Likelihood Explanation

Exploitation requires a consuming contract to forward attacker-controlled, unbounded length parameters to Vector constructors or accept very large arrays for processing within the same call. The current repository does not expose such attack vectors in its public interfaces, significantly reducing immediate practical risk. However, the library's API design permits such usage patterns, and future integrations could realistically create exploitable conditions if developers forward user inputs without proper validation.

#### Recommendation

Consider implementing comprehensive bounds validation and overflow protection for the Vector library's memory operations. One approach could be adding explicit checks before arithmetic operations in assembly blocks to ensure that length and allocation parameters remain within safe ranges.

The most effective immediate enhancement would be validating input lengths in `_new(uint256 length_)` and `_resize()` functions to ensure they do not exceed reasonable memory allocation limits. Additionally, consider using checked arithmetic or explicit overflow detection in the assembly sections of `_allocate()` and `_resize()` where multiplication and addition operations occur.

For the allocation function specifically, implement a maximum allocation size check before performing `mul(allocation_, 0x20)` to prevent the multiplication from overflowing. Similarly, in the resize copy loop, validate that `add(mul(length_, 0x20), 0x20)` does not overflow before using it as a loop bound.

These modifications would provide defense-in-depth protection against both accidental large values and potential malicious inputs while maintaining the library's performance characteristics for normal usage patterns.

## Info Findings

### [I-01] Missing schedule validation in vesting creation enables bricked vestings via divide-by-zero

#### Description

The `_createVesting()` function does not validate that the provided `scheduleId` corresponds to an existing schedule before creating a vesting. When a vesting is created with an invalid or nonexistent `scheduleId` (such as 0), the referenced schedule in storage remains uninitialized with all zero values. 

After the vesting start time passes, any attempt to calculate vested amounts or withdraw tokens will access the zero-initialized schedule data. The `_calculateElapsedPeriods()` function will attempt to divide by `secondsInPeriod`, which is zero in an uninitialized schedule, causing a division-by-zero error and reverting all withdrawal attempts. This results in a permanent denial of service where the beneficiary's tokens become permanently locked and unclaimable.

#### Affected Code

<details>
<summary>

[contracts/finance/vesting/AVesting.sol:316-339](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/finance/vesting/AVesting.sol#L316-L339) - `_createVesting()` function

</summary>

```solidity
    function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
        _validateVesting(vesting_);

        AVestingStorage storage $ = _getAVestingStorage();

        Schedule storage _schedule = $.schedules[vesting_.scheduleId];

        if (
            vesting_.vestingStartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod <=
            block.timestamp
        ) revert VestingPastDate();

        uint256 _currentVestingId = ++$.vestingId;

        $.beneficiaryIds[vesting_.beneficiary].add(_currentVestingId);

        $.vestings[_currentVestingId] = vesting_;

        emit VestingCreated(_currentVestingId, vesting_.beneficiary, vesting_.vestingToken);

        return _currentVestingId;
    }
```
</details>

<details>
<summary>

[contracts/finance/vesting/AVesting.sol:485-492](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/finance/vesting/AVesting.sol#L485-L492) - `_calculateElapsedPeriods()` function

</summary>

```solidity
    function _calculateElapsedPeriods(
        uint256 startTime_,
        uint256 timestampUpTo_,
        uint256 secondsInPeriod_
    ) internal pure returns (uint256) {
        return
            timestampUpTo_ > startTime_ ? (timestampUpTo_ - startTime_) / (secondsInPeriod_) : 0;
    }
```
</details>

#### Recommendation

Consider adding validation to verify that the referenced schedule exists before creating a vesting. One approach could be to check that the schedule's `secondsInPeriod` is non-zero, which would indicate the schedule has been properly initialized through the `_createSchedule()` functions that validate these parameters.

```solidity
function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
    _validateVesting(vesting_);

    AVestingStorage storage $ = _getAVestingStorage();

    Schedule storage _schedule = $.schedules[vesting_.scheduleId];
    
    // Validate that the referenced schedule exists
    if (_schedule.scheduleData.secondsInPeriod == 0) {
        revert InvalidScheduleId(vesting_.scheduleId);
    }

    // ... rest of function remains unchanged
}
```

This validation would prevent the creation of vestings that reference nonexistent schedules, eliminating the possibility of bricked vestings due to division-by-zero errors during withdrawal calculations.

### [I-02] RSASSA-PSS verifier fails maskedDB top-bit check, accepting malformed encodings

#### Description

The RSASSA-PSS verification routine in `_pss()` contains critical flaws in its implementation of RFC 8017 bit-constraint checks. The function incorrectly computes the number of excess bits as `sigBits_ = (sigBytes_ * 8 - 1) & 7`, which always evaluates to 7 regardless of the actual modulus bit length. This miscalculation renders the subsequent maskedDB top-bit validation ineffective.

The verification performs a flawed check on line 138: `if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1)`. Due to the incorrect bit computation, this condition checks whether the result equals 1, but bitwise masking operations typically produce either 0 or 0x80, making this comparison practically never trigger. This allows encodings with improperly set top bits in maskedDB to pass validation when they should be rejected according to the EMSA-PSS standard.

Additionally, the code zeroes the top bits of the unmasked DB on lines 148-151 rather than verifying they were already zero, effectively bypassing a mandatory encoding constraint. While RFC 8017 permits this operation in step 7 of the verification algorithm, the primary issue remains the failure to properly enforce the maskedDB top-bit requirements in step 4.

#### Affected Code

<details>
<summary>

[contracts/libs/crypto/RSASSAPSS.sol:104-151](https://github.com/dl-solarity/solidity-lib/blob/9d18920512954a50508a60b0e84248eb917e2d1e/contracts/libs/crypto/RSASSAPSS.sol#L104-L151)

</summary>

```solidity
    function _pss(
        bytes memory message_,
        bytes memory signature_,
        Parameters memory params_
    ) private pure returns (bool) {
        unchecked {
            uint256 hashLength_ = params_.hashLength;
            uint256 saltLength_ = params_.saltLength;
            uint256 sigBytes_ = signature_.length;
            uint256 sigBits_ = (sigBytes_ * 8 - 1) & 7;

            assert(message_.length < 2 ** 61);

            bytes memory messageHash_ = params_.hasher(message_);

            if (sigBytes_ < hashLength_ + saltLength_ + 2) {
                return false;
            }

            if (signature_[sigBytes_ - 1] != hex"BC") {
                return false;
            }

            bytes memory db_ = new bytes(sigBytes_ - hashLength_ - 1);
            bytes memory h_ = new bytes(hashLength_);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] = signature_[i];
            }

            for (uint256 i = 0; i < hashLength_; ++i) {
                h_[i] = signature_[i + db_.length];
            }

            if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
                return false;
            }

            bytes memory dbMask_ = _mgf(params_, h_, db_.length);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] ^= dbMask_[i];
            }

            if (sigBits_ > 0) {
                db_[0] &= bytes1(uint8(0xFF >> (8 - sigBits_)));
            }
```
</details>

#### Recommendation

Consider correcting the excess-bit calculation to properly reflect the modulus bit length rather than using a hardcoded formula. The `sigBits_` computation should account for the actual number of bits in the RSA modulus to ensure proper validation of the top bits in maskedDB. One approach could be to derive the correct bit count from the modulus length or accept it as a parameter to ensure RFC 8017 compliance. Additionally, review the maskedDB top-bit check logic to ensure it properly validates the constraint rather than using an ineffective equality comparison.

## Statistics

- Total Findings: 15
- Leads Generated: 159
- Clues Generated: 7602
- Verifications Completed: 0
- Synthesis Reports: 0
