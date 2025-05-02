![](https://github.com/dl-solarity/solidity-lib/assets/47551140/87464015-a97a-4f5b-a16f-b34c98eb6549)

[![npm](https://img.shields.io/npm/v/@solarity/solidity-lib.svg)](https://www.npmjs.com/package/@solarity/solidity-lib)
[![Coverage Status](https://codecov.io/gh/dl-solarity/solidity-lib/graph/badge.svg)](https://codecov.io/gh/dl-solarity/solidity-lib)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitPOAP Badge](https://public-api.gitpoap.io/v1/repo/dl-solarity/solidity-lib/badge)](https://www.gitpoap.io/gh/dl-solarity/solidity-lib)

# Solarity Solidity Library

Solidity contracts and utilities that **go far beyond mediocre solidity**.

## Contracts

```ml
contracts
├── access
│   ├── AMerkleWhitelisted — "Whitelists via Merkle proofs"
│   ├── AMultiOwnable — "Multiple owners with the equal access level"
│   ├── ARBAC — "A powerful implementation of a true RBAC"
│   └── extensions
│       └── ARBACGroupable — "Groupable extension of ARBAC"
├── contracts—registry
│   ├── AContractsRegistry — "Reference registry implementation of ERC-6224 pattern"
│   ├── ADependant — "Reference dependant implementation of ERC-6224 pattern"
│   └── pools
│       ├── APoolContractsRegistry — "Adaptation of ERC-6224 for factory-like contracts"
│       └── APoolFactory — "Factory implementation for a pooled registry"
├── diamond
│   ├── ADiamondStorage — "The storage part of ERC-2535 diamond"
│   ├── Diamond — "Revised ERC-2535 diamond implementation"
│   └── utils
│       └── DiamondERC165 — "ERC-165 introspection for diamond facets"
├── finance
│   ├── compound—rate—keeper
│   │   └── ACompoundRateKeeper — "Complex percentage calculator used in lending protocols"
│   ├── staking
│   │   ├── AStaking — "Flexible rewards staking implementation"
│   │   └── AValueDistributor — "Efficient distribution algorithm implementation"
│   └── vesting
│       └── AVesting — "Linear and exponential vesting implementation"
├── libs
│   ├── arrays
│   │   ├── ArrayHelper — "Common functions to work with arrays"
│   │   ├── Paginator — "Return array slices from view function"
│   │   └── SetHelper — "Array abstraction over sets"
│   ├── bn
│   │   └── U512 — "A hyperoptimized uint512 implementation"
│   ├── crypto
│   │   ├── EC256 — "Elliptic curve arithmetic over a 256-bit prime field"
│   │   ├── ECDSA256 — "ECDSA verification over any 256-bit curve"
│   │   ├── ECDSA384 — "ECDSA verification over any 384-bit curve"
│   │   ├── ECDSA512 — "ECDSA verification over any 512-bit curve"
│   │   ├── Schnorr256 — "Schnorr signature verification over any 256-bit curve"
│   │   └── RSASSAPSS — "RSASSA-PSS signature verification with MGF1"
│   ├── data—structures
│   │   ├── AvlTree — "AVL tree implementation with an iterator traversal"
│   │   ├── CartesianMerkleTree — "CMT reference implementation"
│   │   ├── DynamicSet — "Set for strings and bytes"
│   │   ├── IncrementalMerkleTree — "IMT implementation with flexible tree height"
│   │   ├── PriorityQueue — "Max queue heap implementation"
│   │   ├── SparseMerkleTree — "SMT optimized implementation"
│   │   └── memory
│   │       └── Vector — "A pushable memory array"
│   ├── utils
│   │   ├── DecimalsConverter — "Simplify interaction with ERC-20 decimals"
│   │   ├── MemoryUtils — "Functions for memory manipulation"
│   │   ├── ReturnDataProxy — "Bypass extra returndata copy when returning data"
│   │   └── Typecaster — "Cast between various Solidity types"
│   └── zkp
│       ├── Groth16VerifierHelper — "Simplify integration with Groth16 proofs"
│       └── PlonkVerifierHelper — "Simplify integration with Plonk proofs"
├── oracles
│   ├── AUniswapV2Oracle — "Uniswap V2 oracle with custom TWAP"
│   └── UniswapV3Oracle — "Uniswap V3 oracle with a clean interface"
├── proxy
│   └── adminable
│       ├── AdminableProxy — "A slight modification of a transparent proxy"
│       └── AdminableProxyUpgrader — "A slight modification of a proxy admin"
├── tokens
│   └── ASBT — "A minimal implementation of an SBT"
├── utils
│   ├── ABlockGuard — "Protect against flashloans"
│   └── Globals — "Some commonly used constants"
├── presets — "Presets for the library contracts"
├── interfaces — "Interfaces for the library contracts"
└── mock — "Mocks for testing purposes"
```

Built with courage and aspiration to perfection.

> [!TIP]
> The library is designed to work cohesively with [hardhat-zkit](https://github.com/dl-solarity/hardhat-zkit) and [circom-lib](https://github.com/dl-solarity/circom-lib) packages.

## Installation

```bash
npm install @solarity/solidity-lib
```

The latest stable version is always in the `master` branch.

## Documentation

Check out the project's [documentation](https://docs.solarity.dev) with broad explanations and usage examples of every contract. Full `natspec` guides are also available in the source code.

## Contribution

We are open to any mind-blowing ideas! Please take a look at our [contribution guidelines](https://docs.solarity.dev/docs/getting-started/contribution/how-to-contribute) to get involved.

## License

The library is released under the MIT License.
