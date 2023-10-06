import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MerkleTree } from "merkletreejs";
import { expect } from "chai";
import { getRoot, buildSparseMerkleTree } from "../../helpers/merkle-tree-helper";
import { Reverter } from "@/test/helpers/reverter";

import { IncrementalMerkleTreeMock } from "@ethers-v6";

describe("IncrementalMerkleTree", () => {
  const reverter = new Reverter();
  const coder = ethers.AbiCoder.defaultAbiCoder();

  let OWNER: SignerWithAddress;
  let USER1: SignerWithAddress;

  let merkleTree: IncrementalMerkleTreeMock;

  let localMerkleTree: MerkleTree;

  before(async () => {
    [OWNER, USER1] = await ethers.getSigners();

    const IncrementalMerkleTreeMock = await ethers.getContractFactory("IncrementalMerkleTreeMock");
    merkleTree = await IncrementalMerkleTreeMock.deploy();

    localMerkleTree = buildSparseMerkleTree([], 0);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  function getBytes32ElementHash(element: any) {
    return ethers.keccak256(coder.encode(["bytes32"], [element]));
  }

  function getUintElementHash(element: any) {
    return ethers.keccak256(coder.encode(["uint256"], [element]));
  }

  function getAddressElementHash(element: any) {
    return ethers.keccak256(coder.encode(["address"], [element]));
  }

  describe("Uint IMT", () => {
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

      for (let i = 1; i < 33; i++) {
        const element = i;

        await merkleTree.addUint(element);

        const elementHash = getUintElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getUintTreeHeight()));

        expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));

        expect(await merkleTree.getUintTreeLength()).to.equal(BigInt(i));
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getUintRoot()).to.equal(getRoot(localMerkleTree));
    });
  });

  describe("Bytes32 IMT", () => {
    it("should add element to tree", async () => {
      const element = "0x1234";

      await merkleTree.addBytes32(element);

      const elementHash = getBytes32ElementHash("0x1234");

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));

      expect(await merkleTree.getBytes32TreeLength()).to.equal(1n);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 33; i++) {
        const element = `0x${i}234`;

        await merkleTree.addBytes32(element);

        const elementHash = getBytes32ElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getBytes32TreeHeight()));

        expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));

        expect(await merkleTree.getBytes32TreeLength()).to.equal(BigInt(i));
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getBytes32Root()).to.equal(getRoot(localMerkleTree));
    });
  });

  describe("Address IMT", () => {
    it("should add element to tree", async () => {
      const element = USER1;

      await merkleTree.addAddress(element);

      const elementHash = getAddressElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));

      expect(await merkleTree.getAddressTreeLength()).to.equal(1n);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 10; i++) {
        const element = (await ethers.getSigners())[i];

        await merkleTree.addAddress(element);

        const elementHash = getAddressElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, Number(await merkleTree.getAddressTreeHeight()));

        expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));

        expect(await merkleTree.getAddressTreeLength()).to.equal(BigInt(i));
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      expect(await merkleTree.getAddressRoot()).to.equal(getRoot(localMerkleTree));
    });
  });
});
