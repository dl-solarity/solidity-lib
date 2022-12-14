[![npm](https://img.shields.io/npm/v/@dlsl/dev-modules.svg)](https://www.npmjs.com/package/@dlsl/dev-modules) 
[![Coverage Status](https://codecov.io/gh/distributedlab-solidity-library/dev-modules/graph/badge.svg)](https://codecov.io/gh/distributedlab-solidity-library/dev-modules)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Solidity Development Modules by Distributed Lab

**Handful solidity development modules library by DL.**

The library consist of modules and utilities that are built on top of [Openzeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) but goes far beyond the mediocre solidity. 

- Implementation of **Contracts Registry** pattern
- Versatile **RBAC** smart contract
- Enhanced and simplified **Diamond** pattern
- Utilities to ease work with ERC20 decimals, arrays and sets

## Overview

### Installation

```console
$ npm install @dlsl/dev-modules
```

The latest stable version is always in the `master` branch.

## Usage

You will find the smart contracts in the `/contracts` directory. Fell free to play around and check the source code, it is rather descriptive.

Once the [npm package](https://www.npmjs.com/package/@dlsl/dev-modules) is installed, one can use the modules just like that:

```solidity
pragma solidity ^0.8.4;

import "@dlsl/dev-modules/contracts-registry/presets/OwnableContractsRegistry.sol";

contract ContractsRegistry is OwnableContractsRegistry {
    . . .
}
```

> It is important to use the library as it is shipped and not copy-paste the code from untrusted sources.

## License

The development modules are released under the MIT License.
