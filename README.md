![](https://github.com/dl-solarity/solidity-lib/assets/47551140/87464015-a97a-4f5b-a16f-b34c98eb6549)

[![npm](https://img.shields.io/npm/v/@solarity/solidity-lib.svg)](https://www.npmjs.com/package/@solarity/solidity-lib)
[![Coverage Status](https://codecov.io/gh/dl-solarity/solidity-lib/graph/badge.svg)](https://codecov.io/gh/dl-solarity/solidity-lib)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitPOAP Badge](https://public-api.gitpoap.io/v1/repo/dl-solarity/solidity-lib/badge)](https://www.gitpoap.io/gh/dl-solarity/solidity-lib)

# Solidity Library for Savvies

Solidity modules and utilities that **go far beyond mediocre solidity**.

- Implementation of [**Contracts Registry**](https://eips.ethereum.org/EIPS/eip-6224) pattern
- Versatile access control smart contracts (**Merkle whitelists**, **RBAC**)
- Enhanced and simplified [**Diamond**](https://eips.ethereum.org/EIPS/eip-2535) pattern
- Advanced data structures (**Vector**, **DynamicSet**, **PriorityQueue**, **AVLTree**)
- ZK-friendly [**Sparse Merkle Tree**](https://docs.iden3.io/publications/pdfs/Merkle-Tree.pdf) and [**Incremental Merkle Tree**](https://github.com/runtimeverification/deposit-contract-verification/blob/master/deposit-contract-verification.pdf) implementations
- Flexible finance primitives (**Staking**, **Vesting**)
- Robust UniswapV2 and UniswapV3 oracles
- Lightweight SBT implementation
- Utilities to ease work with memory, ERC20 decimals, arrays, sets, and ZK proofs

Built with the help of [Openzeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) (5.1.0).

## Overview

### Installation

```console
$ npm install @solarity/solidity-lib
```

The latest stable version is always in the `master` branch.

### Documentation

Check out the project's [documentation](https://docs.solarity.dev) with broad explanations and usage examples of every module. Full `natspec` guides are also available in the source code.

## Usage

You will find the smart contracts in the `/contracts` directory. Feel free to play around and check the project's structure.

Once the [npm package](https://www.npmjs.com/package/@solarity/solidity-lib) is installed, one can use the library just like that:

```solidity
pragma solidity ^0.8.21;

import {OwnableContractsRegistry} from "@solarity/solidity-lib/contracts-registry/presets/OwnableContractsRegistry.sol";

contract ContractsRegistry is OwnableContractsRegistry {
    . . .
}
```

> [!IMPORTANT]
> It is important to use the library as it is shipped and not copy-paste the code from untrusted sources.

## Contribution

We are open to any mind-blowing ideas! Please take a look at our [contribution guidelines](https://docs.solarity.dev/docs/getting-started/contribution/how-to-contribute) to get involved.

## License

The library is released under the MIT License.
