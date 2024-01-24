import { expect } from "chai";
import { ethers } from "hardhat";

import { MerkleTree } from "merkletreejs";

import { IncrementalMerkleTreeMock } from "@ethers-v6";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getPoseidon, poseidonHash } from "@/test/helpers/poseidon-hash";
import { getRoot, buildSparseMerkleTree } from "@/test/helpers/merkle-tree-helper";

describe("IncrementalMerkleTree", () => {
  const reverter = new Reverter();
  const coder = ethers.AbiCoder.defaultAbiCoder();

  let USER1: SignerWithAddress;

  let merkleTree: IncrementalMerkleTreeMock;

  let localMerkleTree: MerkleTree;

  before("setup", async () => {
    [USER1] = await ethers.getSigners();

    const IncrementalMerkleTreeMock = await ethers.getContractFactory("IncrementalMerkleTreeMock", {
      libraries: {
        PoseidonUnit1L: await (await getPoseidon(1)).getAddress(),
        PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
      },
    });
    merkleTree = await IncrementalMerkleTreeMock.deploy();

    await reverter.snapshot();
  });

  beforeEach("setup", async () => {
    localMerkleTree = buildSparseMerkleTree([], 0);
  });

  afterEach(reverter.revert);

  function getBytes32ElementHash(element: any, hashFn: any = ethers.keccak256) {
    return hashFn(coder.encode(["bytes32"], [element]));
  }

  function getUintElementHash(element: any, hashFn: any = ethers.keccak256) {
    return hashFn(coder.encode(["uint256"], [element]));
  }

  function getAddressElementHash(element: any, hashFn: any = ethers.keccak256) {
    return hashFn(coder.encode(["address"], [element]));
  }

  describe("Uint IMT", () => {
    it("should build a Merkle Tree with predefined size", async () => {
      await merkleTree.newUintTree(10);

      const element = 2341;

      await merkleTree.addUint(element);

      const elementHash = getUintElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 10);

      expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getUintTreeLength()).to.equal(1n);
      expect(await merkleTree.getUintTreeHeight()).to.equal(10n);
    });

    it("should add element to tree", async () => {
      const element = 1234;

      await merkleTree.addUint(element);

      const elementHash = getUintElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getUintTreeLength()).to.equal(1n);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 17; i++) {
        const element = i;

        await merkleTree.addUint(element);

        const elementHash = getUintElementHash(element);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getUintTreeHeight()));

        expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getUintTreeLength()).to.equal(BigInt(i));
      }
    });

    it("should build Merkle Tree correctly and set external Hashers only if the tree is empty", async () => {
      await merkleTree.setUintPoseidonHasher();

      const elements = [];

      for (let i = 1; i < 17; i++) {
        const element = i;

        await merkleTree.addUint(element);

        const elementHash = getUintElementHash(element, poseidonHash);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getUintTreeHeight()), poseidonHash);

        expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getUintTreeLength()).to.equal(BigInt(i));
      }

      expect(await merkleTree.isUnitHashFnSet()).to.be.true;

      await expect(merkleTree.setUintPoseidonHasher()).to.be.rejectedWith(
        "IncrementalMerkleTree: The tree must be empty.",
      );
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
    });
  });

  describe("Bytes32 IMT", () => {
    it("should build a Merkle Tree with predefined size", async () => {
      await merkleTree.newBytes32Tree(10);

      const element = ethers.encodeBytes32String(`0x1234`);

      await merkleTree.addBytes32(element);

      const elementHash = getBytes32ElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 10);

      expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getBytes32TreeLength()).to.equal(1n);
      expect(await merkleTree.getBytes32TreeHeight()).to.equal(10n);
    });

    it("should add element to tree", async () => {
      const element = ethers.encodeBytes32String(`0x1234`);

      await merkleTree.addBytes32(element);

      const elementHash = getBytes32ElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getBytes32TreeLength()).to.equal(1n);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 17; i++) {
        const element = ethers.encodeBytes32String(`0x${i}234`);

        await merkleTree.addBytes32(element);

        const elementHash = getBytes32ElementHash(element);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getBytes32TreeHeight()));

        expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getBytes32TreeLength()).to.equal(BigInt(i));
      }
    });

    it("should build Merkle Tree correctly and set external Hashers only if the tree is empty", async () => {
      await merkleTree.setBytes32PoseidonHasher();

      const elements = [];

      for (let i = 1; i < 17; i++) {
        const element = ethers.encodeBytes32String(`0x${i}234`);

        await merkleTree.addBytes32(element);

        const elementHash = getBytes32ElementHash(element, poseidonHash);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(
          elements,
          Number(await merkleTree.getBytes32TreeHeight()),
          poseidonHash,
        );

        expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getBytes32TreeLength()).to.equal(BigInt(i));
      }

      expect(await merkleTree.isBytes32HashFnSet()).to.be.true;

      await expect(merkleTree.setBytes32PoseidonHasher()).to.be.rejectedWith(
        "IncrementalMerkleTree: The tree must be empty.",
      );
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
    });
  });

  describe("Address IMT", () => {
    it("should build a Merkle Tree with predefined size", async () => {
      await merkleTree.newAddressTree(10);

      const element = USER1.address;

      await merkleTree.addAddress(element);

      const elementHash = getAddressElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 10);

      expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getAddressTreeLength()).to.equal(1n);
      expect(await merkleTree.getAddressTreeHeight()).to.equal(10n);
    });

    it("should add element to tree", async () => {
      const element = USER1.address;

      await merkleTree.addAddress(element);

      const elementHash = getAddressElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
      expect(await merkleTree.getAddressTreeLength()).to.equal(1n);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 17; i++) {
        const element = (await ethers.getSigners())[i].address;

        await merkleTree.addAddress(element);

        const elementHash = getAddressElementHash(element);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getAddressTreeHeight()));

        expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getAddressTreeLength()).to.equal(BigInt(i));
      }
    });

    it("should build Merkle Tree correctly and set external Hashers only if the tree is empty", async () => {
      await merkleTree.setAddressPoseidonHasher();

      const elements = [];

      for (let i = 1; i < 5; i++) {
        const element = (await ethers.getSigners())[i].address;

        await merkleTree.addAddress(element);

        const elementHash = getAddressElementHash(element, poseidonHash);
        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(
          elements,
          Number(await merkleTree.getAddressTreeHeight()),
          poseidonHash,
        );

        expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
        expect(await merkleTree.getAddressTreeLength()).to.equal(BigInt(i));
      }

      expect(await merkleTree.isAddressHashFnSet()).to.be.true;

      await expect(merkleTree.setAddressPoseidonHasher()).to.be.rejectedWith(
        "IncrementalMerkleTree: The tree must be empty.",
      );
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
    });
  });
});
