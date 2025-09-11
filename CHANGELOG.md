# Changelog

## [none]

_ Clarified CI sequence.

## [3.2.5]

- Separated txid and wtxid calculations in `TxParser` library.

## [3.2.4]

- Added `ARecoverableAccount` contract, an all-in-one EIP-7702/ERC-4337 account with ERC-7821 batching, ERC-4337 gas sponsorship, and ERC-7947 recovery.
- Added eslint.

## [3.2.3]

- Slightly extended Merkle Trees functionality. Added `processProof` function.

## [3.2.2]

- Migrated to Hardhat 3.

## [3.2.1]

- Added `Bridge v0.1` contracts for simple cross-chain token transfers. AMB + modules will be added in the subsequent releases.
- Added `verifyProof` function to the `CartesianMerkleTree` and the `IncrementalMerkleTree` libraries.
- Removed `CompoundRateKeeper` contract in favor of PRBMath library.
- Fixed `pre-release` GitHub CI workflow.

## [3.2.0]

Added several new libs to work with Bitcoin:

- `BlockHeader` to parse and format Bitcoin block headers.
- `TxMerkleProof` to verify the inclusion of a Bitcoin transaction in a block.
- `TxParser` to parse and format Bitcoin transactions.
- `EndianConverter` to convert between little-endian and big-endian formats.

Removed rarely used, legacy libs and contracts:

- `SetHelper`.
- `UniswapV2Oracle`.
- `UniswapV3Oracle`.
