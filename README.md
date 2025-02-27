![](https://github.com/dl-solarity/solidity-lib/assets/47551140/87464015-a97a-4f5b-a16f-b34c98eb6549)

[![npm](https://img.shields.io/npm/v/@solarity/solidity-lib.svg)](https://www.npmjs.com/package/@solarity/solidity-lib)
[![Coverage Status](https://codecov.io/gh/dl-solarity/solidity-lib/graph/badge.svg)](https://codecov.io/gh/dl-solarity/solidity-lib)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitPOAP Badge](https://public-api.gitpoap.io/v1/repo/dl-solarity/solidity-lib/badge)](https://www.gitpoap.io/gh/dl-solarity/solidity-lib)

# Solarity Solidity Library

Solidity modules and utilities that **go far beyond mediocre solidity**.

- Implementation of the [**Contracts Registry**](https://eips.ethereum.org/EIPS/eip-6224) pattern
- State-of-the-art cryptography primitives (**ECDSA over 256-bit, 384-bit, and 512-bit curves**, **RSASSA-PSS**)
- Advanced data structures (**Vector**, **DynamicSet**, **PriorityQueue**, **AVLTree**)
- ZK-friendly [**Cartesian Merkle Tree**](https://medium.com/@Arvolear/cartesian-merkle-tree-the-new-breed-a30b005ecf27), [**Sparse Merkle Tree**](https://docs.iden3.io/publications/pdfs/Merkle-Tree.pdf), and [**Incremental Merkle Tree**](https://github.com/runtimeverification/deposit-contract-verification/blob/master/deposit-contract-verification.pdf) implementations
- Versatile access control smart contracts (**Merkle whitelists**, **RBAC**)
- Enhanced and simplified [**Diamond**](https://eips.ethereum.org/EIPS/eip-2535) pattern
- Flexible finance instruments (**Staking**, **Vesting**)
- Robust UniswapV2 and UniswapV3 oracles
- Lightweight SBT implementation
- Hyperoptimized **uint512** BigInt library
- Utilities to ease work with memory, types, ERC20 decimals, arrays, sets, and ZK proofs

Built with courage and aspiration to perfection.

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

import {AMultiOwnable} from "@solarity/solidity-lib/access/AMultiOwnable.sol";
import {TypeCaster} from "@solarity/solidity-lib/libs/utils/TypeCaster.sol";
import {CartesianMerkleTree} from "@solarity/solidity-lib/libs/data-structures/CartesianMerkleTree.sol";
import {Groth16VerifierHelper} from "@solarity/solidity-lib/libs/zkp/Groth16VerifierHelper.sol";

contract Example is AMultiOwnable {
    using CartesianMerkleTree for CartesianMerkleTree.UintCMT;
    using Groth16VerifierHelper for address;
    
    CartesianMerkleTree.UintCMT internal _uintTreaple;
    address internal _treapleVerifier;

    function __Example_init(address treapleVerifier_) initializer {
        __AMultiOwnable_init();
        _uintTreaple.initialize(40);
        _treapleVerifier = treapleVerifier_;
    }

    function addToTree(uint256 key_) external onlyOwner {
        _uintTreaple.add(key_);
    }

    function getMerkleProof(uint256 key_) external view returns (CartesianMerkleTree.Proof memory) {
        return _uintTreaple.getProof(key_, 0);
    }

    function verifyZKProof(Groth16VerifierHelper.ProofPoints memory proof_) external view {
        uint256[] memory pubSignals_ = TypeCaster.asSingletonArray(_uintTreaple.getRoot());

        require(_treapleVerifier.verifyProof(proof_, pubSignals_), "ZKP verification failed");
    }
}
```

This example showcases the basic usage of a `CartesianMerkleTree` with ZK proofs. The contract's `MultiOwner` may add elements to the tree to then privately prove their existence. Also, the `Groth16VerifierHelper` library is used to simplify the interaction with the ZK verifier.

> [!TIP]
> The library is designed to work cohesively with [hardhat-zkit](https://github.com/dl-solarity/hardhat-zkit) and [circom-lib](https://github.com/dl-solarity/circom-lib) packages.

## Contribution

We are open to any mind-blowing ideas! Please take a look at our [contribution guidelines](https://docs.solarity.dev/docs/getting-started/contribution/how-to-contribute) to get involved.

## License

The library is released under the MIT License.
