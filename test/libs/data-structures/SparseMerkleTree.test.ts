import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { getPoseidon, poseidonHash } from "@test-helpers";

import { SparseMerkleTree } from "@/generated-types/ethers/mock/libs/data-structures/SparseMerkleTreeMock.sol/SparseMerkleTreeMock.ts";
import { SparseMerkleTreeMock } from "@ethers-v6";

// @ts-ignore
import { Hash, LocalStorageDB, Merkletree, Proof, str2Bytes, verifyProof } from "@iden3/js-merkletree";
import "mock-local-storage";

const { ethers } = await hre.network.connect();

describe("SparseMerkleTree", () => {
  let USER1: HardhatEthersSigner;

  let merkleTree: SparseMerkleTreeMock;

  let storage: LocalStorageDB;

  let localMerkleTree: Merkletree;

  beforeEach("setup", async () => {
    [USER1] = await ethers.getSigners();

    const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
      libraries: {
        PoseidonUnit2L: await (await getPoseidon(ethers, 2)).getAddress(),
        PoseidonUnit3L: await (await getPoseidon(ethers, 3)).getAddress(),
      },
    });
    merkleTree = await SparseMerkleTreeMock.deploy();

    storage = new LocalStorageDB(str2Bytes(""));

    localMerkleTree = new Merkletree(storage, true, 20);
  });

  afterEach("cleanup", async () => {
    localStorage.clear();
  });

  async function getRoot(tree: Merkletree): Promise<string> {
    return ethers.toBeHex((await tree.root()).bigInt(), 32);
  }

  function getOnchainProof(onchainProof: SparseMerkleTree.ProofStructOutput): Proof {
    const modifiableArray = JSON.parse(JSON.stringify(onchainProof.siblings)).reverse() as string[];
    const reversedKey = modifiableArray.findIndex((value) => value !== ethers.ZeroHash);
    const lastKey = reversedKey !== -1 ? onchainProof.siblings.length - 1 - reversedKey : -1;

    const siblings = onchainProof.siblings
      .filter((value, key) => value != ethers.ZeroHash || key <= lastKey)
      .map((sibling: string) => new Hash(Hash.fromHex(sibling.slice(2)).value.reverse()));

    let nodeAux: { key: Hash; value: Hash } | undefined = undefined;

    if (onchainProof.auxExistence) {
      nodeAux = {
        key: new Hash(Hash.fromHex(onchainProof.auxKey.slice(2)).value.reverse()),
        value: new Hash(Hash.fromHex(onchainProof.auxValue.slice(2)).value.reverse()),
      };
    }

    return new Proof({
      siblings,
      existence: onchainProof.existence,
      nodeAux,
    });
  }

  async function compareNodes(node: SparseMerkleTree.NodeStructOutput, key: bigint) {
    const localNode = await localMerkleTree.get(key);

    expect(node.key).to.equal(ethers.toBeHex(localNode.key, 32));
    expect(node.value).to.equal(ethers.toBeHex(localNode.value, 32));
  }

  describe("Uint SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeUintTree(20);
      await merkleTree.setUintPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeUintTree(20))
        .to.be.revertedWithCustomError(merkleTree, "TreeAlreadyInitialized")
        .withArgs();
    });

    it("should revert if trying to set incorrect max depth", async () => {
      await expect(merkleTree.setMaxDepthUintTree(0))
        .to.be.revertedWithCustomError(merkleTree, "MaxDepthIsZero")
        .withArgs();

      await expect(merkleTree.setMaxDepthUintTree(15))
        .to.be.revertedWithCustomError(merkleTree, "NewMaxDepthMustBeLarger")
        .withArgs(merkleTree.getUintMaxDepth(), 15);

      await expect(merkleTree.setMaxDepthUintTree(300))
        .to.be.revertedWithCustomError(merkleTree, "MaxDepthExceedsHardCap")
        .withArgs(300);
    });

    it("should set max depth bigger than the current one", async () => {
      await merkleTree.setMaxDepthUintTree(21);

      expect(await merkleTree.getUintMaxDepth()).to.equal(21);
    });

    it("should revert if trying to call add/remove/update functions on non-initialized tree", async () => {
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(ethers, 2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(ethers, 3)).getAddress(),
        },
      });
      const newMerkleTree = await SparseMerkleTreeMock.deploy();

      await expect(newMerkleTree.addUint(ethers.toBeHex(1n, 32), 1n))
        .to.be.revertedWithCustomError(merkleTree, "TreeNotInitialized")
        .withArgs();

      await expect(newMerkleTree.removeUint(ethers.toBeHex(1n, 32)))
        .to.be.revertedWithCustomError(merkleTree, "TreeNotInitialized")
        .withArgs();

      await expect(newMerkleTree.updateUint(ethers.toBeHex(1n, 32), 1n))
        .to.be.revertedWithCustomError(merkleTree, "TreeNotInitialized")
        .withArgs();
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = 2341n;
      const key = poseidonHash(ethers.toBeHex(value));

      expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

      await merkleTree.addUint(key, value);

      await localMerkleTree.add(BigInt(key), value);

      expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getUintMaxDepth()).to.equal(20);
      expect(await merkleTree.getUintNodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getUintNode(1), BigInt(key));
      await compareNodes(await merkleTree.getUintNodeByKey(key), BigInt(key));

      const onchainProof = getOnchainProof(await merkleTree.getUintProof(key));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), value)).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const key = poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32));

        await merkleTree.addUint(key, value);

        await localMerkleTree.add(BigInt(key), value);

        expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getUintNodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getUintProof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), value)).to.be.true;
      }

      expect(await merkleTree.isUintCustomHasherSet()).to.be.true;

      await expect(merkleTree.setUintPoseidonHasher())
        .to.be.revertedWithCustomError(merkleTree, "TreeIsNotEmpty")
        .withArgs();
    });

    it("should add and full remove elements from Merkle Tree correctly", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const key = poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32));

        await merkleTree.addUint(key, value);

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);

        await merkleTree.removeUint(key);
      }

      expect(await merkleTree.getUintRoot()).to.equal(ethers.ZeroHash);

      expect(await merkleTree.getUintNodesCount()).to.equal(0);

      expect(await merkleTree.isUintCustomHasherSet()).to.be.true;
      expect(merkleTree.setUintPoseidonHasher()).to.not.be.rejected;
    });

    it("should maintain idempotence", async () => {
      const keys: string[] = [];
      let proof;

      for (let i = 1n; i < 20n; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const key = poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32));

        await merkleTree.addUint(key, value);

        if (i > 1n) {
          await merkleTree.removeUint(key);

          const hexKey = ethers.toBeHex(keys[Number(i - 2n)], 32);
          expect(await merkleTree.getUintProof(hexKey)).to.deep.equal(proof);

          await merkleTree.addUint(key, value);
        }

        proof = await merkleTree.getUintProof(key);

        keys.push(key);
      }

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);
        const value = (await merkleTree.getUintNodeByKey(hexKey)).value;

        proof = await merkleTree.getUintProof(hexKey);

        await merkleTree.removeUint(hexKey);
        await merkleTree.addUint(hexKey, value);

        expect(await merkleTree.getUintProof(hexKey)).to.deep.equal(proof);
      }
    });

    it("should rebalance elements in Merkle Tree correctly", async () => {
      const expectedRoot = "0x2f9bbaa7ab83da6e8d1d8dd05bac16e65fa40b4f6455c1d2ee77e968dfc382dc";
      const keys = [7n, 1n, 5n];

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await merkleTree.addUint(hexKey, key);
      }

      const oldRoot = await merkleTree.getUintRoot();

      expect(oldRoot).to.equal(expectedRoot);
      expect(await merkleTree.getUintNodesCount()).to.equal(6);

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await merkleTree.removeUint(hexKey);
        await merkleTree.addUint(hexKey, key);
      }

      expect(await merkleTree.getUintRoot()).to.equal(oldRoot);
      expect(await merkleTree.getUintNodesCount()).to.equal(6);
    });

    it("should not remove non-existent leaves", async () => {
      const keys = [7n, 1n, 5n];

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await merkleTree.addUint(hexKey, key);
      }

      await expect(merkleTree.removeUint(ethers.toBeHex(8, 32)))
        .to.be.revertedWithCustomError(merkleTree, "NodeDoesNotExist")
        .withArgs(0);

      await expect(merkleTree.removeUint(ethers.toBeHex(9, 32)))
        .to.be.revertedWithCustomError(merkleTree, "LeafDoesNotMatch")
        .withArgs(ethers.toBeHex(1, 32), ethers.toBeHex(9, 32));
    });

    it("should update existing leaves", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const key = poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32));

        await merkleTree.addUint(key, value);
        await localMerkleTree.add(BigInt(key), value);

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));

        await merkleTree.updateUint(key, value);
        await localMerkleTree.update(BigInt(key), value);

        expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getUintNodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getUintProof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), value)).to.be.true;
      }
    });

    it("should not update non-existent leaves", async () => {
      const keys = [7n, 1n, 5n];

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await merkleTree.addUint(hexKey, key);
      }

      await expect(merkleTree.updateUint(ethers.toBeHex(8, 32), 1n))
        .to.be.revertedWithCustomError(merkleTree, "NodeDoesNotExist")
        .withArgs(0);

      await expect(merkleTree.updateUint(ethers.toBeHex(9, 32), 1n))
        .to.be.revertedWithCustomError(merkleTree, "LeafDoesNotMatch")
        .withArgs(ethers.toBeHex(1, 32), ethers.toBeHex(9, 32));
    });

    it("should generate empty proof on empty tree", async () => {
      const onchainProof = getOnchainProof(await merkleTree.getUintProof(ethers.toBeHex(1n, 32)));

      expect(onchainProof.allSiblings()).to.have.length(0);
    });

    it("should generate an empty proof for but with aux fields", async () => {
      await merkleTree.addUint(ethers.toBeHex(7n, 32), 1n);

      const onchainProof = await merkleTree.getUintProof(ethers.toBeHex(5n, 32));

      expect(onchainProof.auxKey).to.equal(7n);
      expect(onchainProof.auxValue).to.equal(1n);
      expect(onchainProof.auxExistence).to.equal(true);
      expect(onchainProof.existence).to.equal(false);
    });

    it("should generate non-membership proof (empty node and different node)", async () => {
      await localMerkleTree.add(3n, 15n); // key -> 0b011
      await localMerkleTree.add(7n, 15n); // key -> 0b111

      await merkleTree.addUint(ethers.toBeHex(3n, 32), 15n);
      await merkleTree.addUint(ethers.toBeHex(7n, 32), 15n);

      let onchainProof = getOnchainProof(await merkleTree.getUintProof(ethers.toBeHex(5n, 32)));
      expect(await verifyProof(await localMerkleTree.root(), onchainProof, 5n, 0n)).to.be.true;

      onchainProof = getOnchainProof(await merkleTree.getUintProof(ethers.toBeHex(15n, 32)));
      expect(await verifyProof(await localMerkleTree.root(), onchainProof, 15n, 15n)).to.be.true;
    });

    it("should revert if trying to add a node with the same key", async () => {
      const value = 2341n;
      const key = poseidonHash(ethers.toBeHex(value));

      await merkleTree.addUint(key, value);

      await expect(merkleTree.addUint(key, value))
        .to.be.revertedWithCustomError(merkleTree, "KeyAlreadyExists")
        .withArgs(key);
    });

    it("should revert if max depth is reached", async () => {
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(ethers, 2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(ethers, 3)).getAddress(),
        },
      });
      const newMerkleTree = await SparseMerkleTreeMock.deploy();

      await newMerkleTree.initializeUintTree(1);

      await newMerkleTree.addUint(ethers.toBeHex(1n, 32), 1n);
      await newMerkleTree.addUint(ethers.toBeHex(2n, 32), 1n);

      await expect(newMerkleTree.addUint(ethers.toBeHex(3n, 32), 1n))
        .to.be.revertedWithCustomError(merkleTree, "MaxDepthReached")
        .withArgs();
    });

    it("should get empty Node by non-existing key", async () => {
      expect((await merkleTree.getUintNodeByKey(1n)).nodeType).to.be.equal(0);

      await merkleTree.addUint(ethers.toBeHex(7n, 32), 1n);

      expect((await merkleTree.getUintNodeByKey(5n)).nodeType).to.be.equal(0);
    });

    it("should handle proof verification correctly", async () => {
      const treeSize = 20;

      const keys: string[] = new Array(treeSize);

      for (let i = 1; i <= treeSize; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const key = poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32));

        keys[i - 1] = key;

        await merkleTree.addUint(key, value);

        await localMerkleTree.add(BigInt(key), BigInt(value));
      }

      const randomNum = Math.floor(Math.random() * (treeSize - 1));
      const randomKey = keys[randomNum];

      const inclusionProof = JSON.parse(JSON.stringify(await merkleTree.getUintProof(randomKey)));

      expect(await merkleTree.verifyUintProof(inclusionProof)).to.be.true;
      expect(await merkleTree.processProof(inclusionProof)).to.be.eq(inclusionProof[0]);

      inclusionProof[0] = inclusionProof[3];
      expect(await merkleTree.verifyUintProof(inclusionProof)).to.be.false;

      await merkleTree.removeUint(randomKey);

      let exclusionProof = JSON.parse(JSON.stringify(await merkleTree.getUintProof(randomKey)));

      expect(await merkleTree.verifyUintProof(exclusionProof)).to.be.true;

      exclusionProof[0] = exclusionProof[3];
      expect(await merkleTree.verifyUintProof(exclusionProof)).to.be.false;

      const [root, siblings, , , value, , , auxValue] = exclusionProof;

      const invalidExclusionProof = {
        root,
        siblings,
        key: randomKey,
        value,
        existence: false,
        auxKey: randomKey,
        auxValue,
        auxExistence: true,
      };

      expect(await merkleTree.verifyUintProof(invalidExclusionProof)).to.be.false;

      do {
        const outOfRangeKey = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);

        exclusionProof = JSON.parse(JSON.stringify(await merkleTree.getUintProof(outOfRangeKey)));
      } while (exclusionProof[2] || exclusionProof[5]);

      expect(await merkleTree.verifyUintProof(exclusionProof)).to.be.true;
    });
  });

  describe("Bytes32 SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeBytes32Tree(15);
      await merkleTree.setBytes32PoseidonHasher();

      await merkleTree.setMaxDepthBytes32Tree(20);
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeBytes32Tree(20))
        .to.be.revertedWithCustomError(merkleTree, "TreeAlreadyInitialized")
        .withArgs();
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = ethers.toBeHex("0x1235", 32);
      const key = poseidonHash(value);

      await merkleTree.addBytes32(key, value);

      await localMerkleTree.add(BigInt(key), BigInt(value));

      expect(await merkleTree.getBytes32Root()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getBytes32MaxDepth()).to.equal(20);
      expect(await merkleTree.getBytes32NodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getBytes32Node(1), BigInt(key));
      await compareNodes(await merkleTree.getBytes32NodeByKey(key), BigInt(key));

      const onchainProof = getOnchainProof(await merkleTree.getBytes32Proof(key));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);
        const key = poseidonHash(value);

        await merkleTree.addBytes32(key, value);

        await localMerkleTree.add(BigInt(key), BigInt(value));

        expect(await merkleTree.getBytes32Root()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getBytes32NodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getBytes32Proof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
      }

      expect(await merkleTree.isBytes32CustomHasherSet()).to.be.true;

      await expect(merkleTree.setBytes32PoseidonHasher())
        .to.be.revertedWithCustomError(merkleTree, "TreeIsNotEmpty")
        .withArgs();
    });

    it("should add and full remove elements from Merkle Tree correctly", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);
        const key = poseidonHash(value);

        await merkleTree.addBytes32(key, value);

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);

        await merkleTree.removeBytes32(key);
      }

      expect(await merkleTree.getBytes32Root()).to.equal(ethers.ZeroHash);

      expect(await merkleTree.getBytes32NodesCount()).to.equal(0);

      expect(await merkleTree.isBytes32CustomHasherSet()).to.be.true;
      expect(merkleTree.setBytes32PoseidonHasher()).to.not.be.rejected;
    });

    it("should update existing leaves", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);
        const key = poseidonHash(value);

        await merkleTree.addBytes32(key, value);
        await localMerkleTree.add(BigInt(key), BigInt(value));

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));

        await merkleTree.updateBytes32(key, ethers.toBeHex(value, 32));
        await localMerkleTree.update(BigInt(key), BigInt(value));

        expect(await merkleTree.getBytes32Root()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getBytes32NodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getBytes32Proof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
      }
    });

    it("should handle proof verification correctly", async () => {
      const treeSize = 20;

      const keys: string[] = new Array(treeSize);

      for (let i = 1; i <= treeSize; i++) {
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);
        const key = poseidonHash(value);

        keys[i - 1] = key;

        await merkleTree.addBytes32(key, value);
      }

      const randomKey = keys[Math.floor(Math.random() * (treeSize - 1))];

      const inclusionProof = JSON.parse(JSON.stringify(await merkleTree.getBytes32Proof(randomKey)));

      expect(await merkleTree.verifyBytes32Proof(inclusionProof)).to.be.true;
      expect(await merkleTree.processProof(inclusionProof)).to.be.eq(inclusionProof[0]);

      inclusionProof[0] = inclusionProof[3];
      expect(await merkleTree.verifyBytes32Proof(inclusionProof)).to.be.false;

      await merkleTree.removeBytes32(randomKey);

      const exclusionProof = JSON.parse(JSON.stringify(await merkleTree.getBytes32Proof(randomKey)));

      expect(await merkleTree.verifyBytes32Proof(exclusionProof)).to.be.true;

      exclusionProof[0] = exclusionProof[3];
      expect(await merkleTree.verifyBytes32Proof(exclusionProof)).to.be.false;
    });
  });

  describe("Address SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeAddressTree(15);
      await merkleTree.setAddressPoseidonHasher();

      await merkleTree.setMaxDepthAddressTree(20);
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeAddressTree(20))
        .to.be.revertedWithCustomError(merkleTree, "TreeAlreadyInitialized")
        .withArgs();
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = await USER1.getAddress();
      const key = poseidonHash(value);

      await merkleTree.addAddress(key, value);

      await localMerkleTree.add(BigInt(key), BigInt(value));

      expect(await merkleTree.getAddressRoot()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getAddressMaxDepth()).to.equal(20);
      expect(await merkleTree.getAddressNodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getAddressNode(1), BigInt(key));
      await compareNodes(await merkleTree.getAddressNodeByKey(key), BigInt(key));

      const onchainProof = getOnchainProof(await merkleTree.getAddressProof(key));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);
        const key = poseidonHash(value);

        await merkleTree.addAddress(key, value);

        await localMerkleTree.add(BigInt(key), BigInt(value));

        expect(await merkleTree.getAddressRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getAddressNodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getAddressProof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
      }

      expect(await merkleTree.isAddressCustomHasherSet()).to.be.true;

      await expect(merkleTree.setAddressPoseidonHasher())
        .to.be.revertedWithCustomError(merkleTree, "TreeIsNotEmpty")
        .withArgs();
    });

    it("should add and full remove elements from Merkle Tree correctly", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);
        const key = poseidonHash(value);

        await merkleTree.addAddress(key, value);

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);

        await merkleTree.removeAddress(key);
      }

      expect(await merkleTree.getAddressRoot()).to.equal(ethers.ZeroHash);

      expect(await merkleTree.getAddressNodesCount()).to.equal(0);

      expect(await merkleTree.isAddressCustomHasherSet()).to.be.true;
      expect(merkleTree.setAddressPoseidonHasher()).to.not.be.rejected;
    });

    it("should update existing leaves", async () => {
      const keys: string[] = [];

      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);
        const key = poseidonHash(value);

        await merkleTree.addAddress(key, value);
        await localMerkleTree.add(BigInt(key), BigInt(value));

        keys.push(key);
      }

      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(keys[Number(i) - 1], 32);
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(20)));

        await merkleTree.updateAddress(key, ethers.toBeHex(value, 20));
        await localMerkleTree.update(BigInt(key), BigInt(value));

        expect(await merkleTree.getAddressRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getAddressNodeByKey(key), BigInt(key));

        const onchainProof = getOnchainProof(await merkleTree.getAddressProof(key));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(key), BigInt(value))).to.be.true;
      }
    });

    it("should handle proof verification correctly", async () => {
      const treeSize = 20;

      const keys: string[] = new Array(treeSize);

      for (let i = 1; i <= treeSize; i++) {
        const value = ethers.toBeHex(BigInt(await USER1.getAddress()) + BigInt(i));
        const key = poseidonHash(value);

        keys[i - 1] = key;

        await merkleTree.addAddress(key, value);
      }

      const randomKey = keys[Math.floor(Math.random() * (treeSize - 1))];

      const inclusionProof = JSON.parse(JSON.stringify(await merkleTree.getAddressProof(randomKey)));

      expect(await merkleTree.verifyAddressProof(inclusionProof)).to.be.true;
      expect(await merkleTree.processProof(inclusionProof)).to.be.eq(inclusionProof[0]);

      inclusionProof[0] = inclusionProof[3];
      expect(await merkleTree.verifyAddressProof(inclusionProof)).to.be.false;

      await merkleTree.removeAddress(randomKey);

      const exclusionProof = JSON.parse(JSON.stringify(await merkleTree.getAddressProof(randomKey)));

      expect(await merkleTree.verifyAddressProof(exclusionProof)).to.be.true;

      exclusionProof[0] = exclusionProof[3];
      expect(await merkleTree.verifyAddressProof(exclusionProof)).to.be.false;
    });
  });
});
