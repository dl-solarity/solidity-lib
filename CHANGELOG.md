# Changelog

## [none]

- Fixed `pre-release` GitHub CI workflow.
- Added `verifyProof` function to the `CartesianMerkleTree` and the `IncrementalMerkleTree` libraries.
- Migrated to Hardhat 3

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
