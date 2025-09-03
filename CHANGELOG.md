# Changelog

## [patch]

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
