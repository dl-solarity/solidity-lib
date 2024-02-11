import { expect } from "chai";
import { ethers } from "hardhat";

import { Hash, LocalStorageDB, Merkletree, Proof, str2Bytes, verifyProof } from "@iden3/js-merkletree";

import { SparseMerkleTreeMock } from "@ethers-v6";
import { SparseMerkleTree } from "@/generated-types/ethers/contracts/mock/libs/data-structures/SparseMerkleTreeMock.sol/SparseMerkleTreeMock";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getPoseidon, poseidonHash } from "@/test/helpers/poseidon-hash";

import "mock-local-storage";

describe("SparseMerkleTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;

  let merkleTree: SparseMerkleTreeMock;

  let storage: LocalStorageDB;

  let localMerkleTree: Merkletree;

  before("setup", async () => {
    [USER1] = await ethers.getSigners();

    const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
      libraries: {
        PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
      },
    });
    merkleTree = await SparseMerkleTreeMock.deploy();

    await reverter.snapshot();
  });

  beforeEach("setup", async () => {
    storage = new LocalStorageDB(str2Bytes(""));

    localMerkleTree = new Merkletree(storage, true, 20);
  });

  afterEach("cleanup", async () => {
    await reverter.revert();

    localStorage.clear();
  });

  async function getRoot(tree: Merkletree): Promise<string> {
    return ethers.toBeHex((await tree.root()).bigInt(), 32);
  }

  function getOnchainProof(onchainProof: SparseMerkleTree.ProofStructOutput): Proof {
    const modifiableArray = JSON.parse(JSON.stringify(onchainProof.siblings)).reverse() as string[];
    const reversedIndex = modifiableArray.findIndex((value) => value !== ethers.ZeroHash);
    const lastIndex = reversedIndex !== -1 ? onchainProof.siblings.length - 1 - reversedIndex : -1;

    return new Proof({
      siblings: onchainProof.siblings
        .filter((value, index) => value != ethers.ZeroHash || index <= lastIndex)
        .map((sibling: string) => new Hash(Hash.fromHex(sibling.replace("0x", "")).value.reverse())),
      existence: onchainProof.existence,
      nodeAux: undefined,
    });
  }

  async function compareNodes(node: SparseMerkleTree.NodeStructOutput, index: bigint) {
    const localNode = await localMerkleTree.get(index);

    expect(node.index).to.equal(ethers.toBeHex(localNode.key, 32));
    expect(node.value).to.equal(ethers.toBeHex(localNode.value, 32));
  }

  describe("Uint SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeUintTree(20);
      await merkleTree.setUintPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeUintTree(20)).to.be.rejectedWith(
        "SparseMerkleTree: tree is already initialized",
      );
    });

    it("should revert if trying to set incorrect max depth", async () => {
      await expect(merkleTree.setMaxDepthUintTree(0)).to.be.rejectedWith(
        "SparseMerkleTree: max depth must be greater than zero",
      );

      await expect(merkleTree.setMaxDepthUintTree(15)).to.be.rejectedWith(
        "SparseMerkleTree: max depth can only be increased",
      );

      await expect(merkleTree.setMaxDepthUintTree(300)).to.be.rejectedWith(
        "SparseMerkleTree: max depth is greater than hard cap",
      );
    });

    it("should set max depth bigger than the current one", async () => {
      await merkleTree.setMaxDepthUintTree(21);

      expect(await merkleTree.getUintMaxDepth()).to.equal(21);
    });

    it("should revert if trying to call add or root function on non-initialized tree", async () => {
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const newMerkleTree = await SparseMerkleTreeMock.deploy();

      await expect(newMerkleTree.getUintRoot()).to.be.rejectedWith("SparseMerkleTree: tree is not initialized");
      await expect(newMerkleTree.addUint(1n, 1n)).to.be.rejectedWith("SparseMerkleTree: tree is not initialized");
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = 2341n;
      const index = BigInt(poseidonHash(ethers.toBeHex(value)));

      await merkleTree.addUint(index, value);

      await localMerkleTree.add(index, value);

      expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getUintMaxDepth()).to.equal(20);
      expect(await merkleTree.getUintNodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getUintNode(1), index);
      await compareNodes(await merkleTree.getUintNodeByIndex(index), index);

      const onchainProof = getOnchainProof(await merkleTree.getUintProof(index));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, index, value)).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = BigInt(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));
        const index = BigInt(poseidonHash(ethers.toBeHex(`0x` + value.toString(16), 32)));

        await merkleTree.addUint(index, value);

        await localMerkleTree.add(index, value);

        expect(await merkleTree.getUintRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getUintNodeByIndex(index), index);

        const onchainProof = getOnchainProof(await merkleTree.getUintProof(index));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, index, value)).to.be.true;
      }

      expect(await merkleTree.isUintCustomHasherSet()).to.be.true;

      await expect(merkleTree.setUintPoseidonHasher()).to.be.rejectedWith("SparseMerkleTree: tree is not empty");
    });

    it("should generate empty proof on empty tree", async () => {
      const onchainProof = getOnchainProof(await merkleTree.getUintProof(1n));

      expect(onchainProof.allSiblings()).to.have.length(0);
    });

    it("should generate an empty proof for but with aux fields", async () => {
      await merkleTree.addUint(7n, 1n);

      const onchainProof = await merkleTree.getUintProof(5n);

      expect(onchainProof.auxIndex).to.equal(7n);
      expect(onchainProof.auxValue).to.equal(1n);
      expect(onchainProof.auxExistence).to.equal(true);
      expect(onchainProof.existence).to.equal(false);
    });

    it("should reset the value of the node", async () => {
      const value = 2341n;
      const index = BigInt(poseidonHash(ethers.toBeHex(value)));

      await merkleTree.addUint(index, value);

      const oldRoot = await merkleTree.getUintRoot();

      expect((await merkleTree.getUintNodeByIndex(index)).value).to.be.equal(ethers.toBeHex(value, 32));

      const newValue = 1234n;

      await merkleTree.addUint(index, newValue);

      expect((await merkleTree.getUintNodeByIndex(index)).value).to.be.equal(ethers.toBeHex(newValue, 32));

      expect(await merkleTree.getUintRoot()).to.not.equal(oldRoot);
    });

    it("should revert if max depth is reached", async () => {
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const newMerkleTree = await SparseMerkleTreeMock.deploy();

      await newMerkleTree.initializeUintTree(1);

      await newMerkleTree.addUint(1n, 1n);
      await newMerkleTree.addUint(2n, 1n);

      await expect(newMerkleTree.addUint(3n, 1n)).to.be.rejectedWith("SparseMerkleTree: max depth reached");
    });

    it("should get empty Node by non-existing index", async () => {
      expect((await merkleTree.getUintNodeByIndex(1n)).nodeType).to.be.equal(0);

      await merkleTree.addUint(7n, 1n);

      expect((await merkleTree.getUintNodeByIndex(5n)).nodeType).to.be.equal(0);
    });
  });

  describe("Bytes32 SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeBytes32Tree(15);
      await merkleTree.setBytes32PoseidonHasher();

      await merkleTree.setMaxDepthBytes32Tree(20);
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeBytes32Tree(20)).to.be.rejectedWith(
        "SparseMerkleTree: tree is already initialized",
      );
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = ethers.toBeHex("0x1235", 32);
      const index = poseidonHash(value);

      await merkleTree.addBytes32(index, value);

      await localMerkleTree.add(BigInt(index), BigInt(value));

      expect(await merkleTree.getBytes32Root()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getBytes32MaxDepth()).to.equal(20);
      expect(await merkleTree.getBytes32NodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getBytes32Node(1), BigInt(index));
      await compareNodes(await merkleTree.getBytes32NodeByIndex(index), BigInt(index));

      const onchainProof = getOnchainProof(await merkleTree.getBytes32Proof(index));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(index), BigInt(value))).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32);
        const index = poseidonHash(value);

        await merkleTree.addBytes32(index, value);

        await localMerkleTree.add(BigInt(index), BigInt(value));

        expect(await merkleTree.getBytes32Root()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getBytes32NodeByIndex(index), BigInt(index));

        const onchainProof = getOnchainProof(await merkleTree.getBytes32Proof(index));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(index), BigInt(value))).to.be.true;
      }

      expect(await merkleTree.isBytes32CustomHasherSet()).to.be.true;

      await expect(merkleTree.setBytes32PoseidonHasher()).to.be.rejectedWith("SparseMerkleTree: tree is not empty");
    });
  });

  describe("Address SMT", () => {
    beforeEach("setup", async () => {
      await merkleTree.initializeAddressTree(15);
      await merkleTree.setAddressPoseidonHasher();

      await merkleTree.setMaxDepthAddressTree(20);
    });

    it("should not initialize twice", async () => {
      await expect(merkleTree.initializeAddressTree(20)).to.be.rejectedWith(
        "SparseMerkleTree: tree is already initialized",
      );
    });

    it("should build a Merkle Tree of a predefined size with correct initial values", async () => {
      const value = await USER1.getAddress();
      const index = poseidonHash(value);

      await merkleTree.addAddress(index, value);

      await localMerkleTree.add(BigInt(index), BigInt(value));

      expect(await merkleTree.getAddressRoot()).to.equal(await getRoot(localMerkleTree));

      expect(await merkleTree.getAddressMaxDepth()).to.equal(20);
      expect(await merkleTree.getAddressNodesCount()).to.equal(1);

      await compareNodes(await merkleTree.getAddressNode(1), BigInt(index));
      await compareNodes(await merkleTree.getAddressNodeByIndex(index), BigInt(index));

      const onchainProof = getOnchainProof(await merkleTree.getAddressProof(index));

      expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(index), BigInt(value))).to.be.true;
    });

    it("should build a Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const value = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);
        const index = poseidonHash(value);

        await merkleTree.addAddress(index, value);

        await localMerkleTree.add(BigInt(index), BigInt(value));

        expect(await merkleTree.getAddressRoot()).to.equal(await getRoot(localMerkleTree));

        await compareNodes(await merkleTree.getAddressNodeByIndex(index), BigInt(index));

        const onchainProof = getOnchainProof(await merkleTree.getAddressProof(index));
        expect(await verifyProof(await localMerkleTree.root(), onchainProof, BigInt(index), BigInt(value))).to.be.true;
      }

      expect(await merkleTree.isAddressCustomHasherSet()).to.be.true;

      await expect(merkleTree.setAddressPoseidonHasher()).to.be.rejectedWith("SparseMerkleTree: tree is not empty");
    });
  });
});
