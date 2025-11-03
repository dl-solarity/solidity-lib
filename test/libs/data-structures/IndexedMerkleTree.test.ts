import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { IndexedMerkleTreeMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("IndexedMerkleTree", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const LEAVES_LEVEL = 0n;

  let indexedMT: IndexedMerkleTreeMock;

  function hashNode(leftChild: string, rightChild: string): string {
    return ethers.solidityPackedKeccak256(["bytes32", "bytes32"], [leftChild, rightChild]);
  }

  function hashLeaf(leafIndex: bigint, value: string, nextLeafIndex: bigint, isActive: boolean): string {
    return ethers.solidityPackedKeccak256(
      ["bool", "uint256", "bytes32", "uint256"],
      [isActive, leafIndex, value, nextLeafIndex],
    );
  }

  function encodeBytes32Value(value: bigint): string {
    return ethers.toBeHex(value, 32);
  }

  before("setup", async () => {
    indexedMT = await ethers.deployContract("IndexedMerkleTreeMock");

    await indexedMT.initializeUintTree();

    await reverter.snapshot();
  });

  afterEach("cleanup", async () => {
    await reverter.revert();
  });

  describe("initialize", () => {
    it("should correctly initialize IndexedMerkleTree", async () => {
      const zeroLeafHash = hashLeaf(0n, ethers.ZeroHash, 0n, true);

      expect(await indexedMT.getRoot()).to.be.eq(zeroLeafHash);
      expect(await indexedMT.getTreeLevels()).to.be.eq(1);
      expect(await indexedMT.getLeavesCount()).to.be.eq(1);
      expect(await indexedMT.getNodeHash(0, LEAVES_LEVEL)).to.be.eq(zeroLeafHash);
    });

    it("should get exception if try to initialize twice", async () => {
      await expect(indexedMT.initializeUintTree()).to.be.revertedWithCustomError(
        indexedMT,
        "IndexedMerkleTreeNotInitialized",
      );
    });
  });

  describe("add", () => {
    it("should correctly add new elements with the increment values", async () => {
      const startIndex = 1n;
      let lowLeafIndex = 0n;
      let lowLeafValue = 0n;
      let value = 10n;

      const count = 10;

      for (let i = 0; i < count; ++i) {
        const currentIndex = startIndex + BigInt(i);

        await indexedMT.addUint(value, lowLeafIndex);

        const leafData = await indexedMT.getLeafData(currentIndex);

        expect(leafData.value).to.be.eq(value);
        expect(leafData.nextLeafIndex).to.be.eq(0n);

        const leafHash = hashLeaf(currentIndex, encodeBytes32Value(value), 0n, true);
        expect(await indexedMT.getNodeHash(currentIndex, LEAVES_LEVEL)).to.be.eq(leafHash);

        const lowLeafData = await indexedMT.getLeafData(lowLeafIndex);

        expect(lowLeafData.value).to.be.eq(lowLeafValue);
        expect(lowLeafData.nextLeafIndex).to.be.eq(currentIndex);

        const lowLeafNewHash = hashLeaf(lowLeafIndex, encodeBytes32Value(lowLeafValue), currentIndex, true);
        expect(await indexedMT.getNodeHash(lowLeafIndex, LEAVES_LEVEL)).to.be.eq(lowLeafNewHash);

        lowLeafIndex = currentIndex;
        lowLeafValue = value;
        value *= 2n;
      }

      const expectedLevelsCount = Math.ceil(Math.log2(count + 1)) + 1;

      expect(await indexedMT.getTreeLevels()).to.be.eq(expectedLevelsCount);
    });

    it("should get exception if pass invalid low leaf index", async () => {
      await indexedMT.addUint(10n, 0n);
      await indexedMT.addUint(20n, 1n);

      await expect(indexedMT.addUint(5n, 1n)).to.be.revertedWithCustomError(indexedMT, "InvalidLowLeaf");
      await expect(indexedMT.addUint(25n, 1n)).to.be.revertedWithCustomError(indexedMT, "InvalidLowLeaf");
    });
  });

  describe("getProof", () => {
    const values: bigint[] = [0n, 10n, 20n, 30n];
    let leaves: string[] = [];

    beforeEach("setup", async () => {
      for (let i = 0; i < values.length; i++) {
        leaves.push(
          hashLeaf(BigInt(i), encodeBytes32Value(values[i]), i == values.length - 1 ? 0n : BigInt(i + 1), true),
        );

        if (i > 0) {
          await indexedMT.addUint(values[i], i - 1);
        }
      }
    });

    afterEach("clean", async () => {
      leaves = [];
    });

    it("should return correct inclusion proof", async () => {
      let index = 2n;
      let value = 20n;
      let nextLeafIndex = 3n;
      let expectedSiblings = [leaves[3], hashNode(leaves[0], leaves[1])];
      let proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(await indexedMT.getRoot());
      expect(proof.existence).to.be.true;
      expect(proof.index).to.be.eq(index);
      expect(proof.value).to.be.eq(value);
      expect(proof.nextLeafIndex).to.be.eq(nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedSiblings);

      index = 1n;
      value = 10n;
      nextLeafIndex = 2n;
      expectedSiblings = [leaves[0], hashNode(leaves[2], leaves[3])];
      proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(await indexedMT.getRoot());
      expect(proof.existence).to.be.true;
      expect(proof.index).to.be.eq(index);
      expect(proof.value).to.be.eq(value);
      expect(proof.nextLeafIndex).to.be.eq(nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedSiblings);
    });

    it("should return correct exclusion proof", async () => {
      const index = 1n;
      const value = 15n;
      const nextLeafIndex = 2n;
      const expectedSiblings = [leaves[0], hashNode(leaves[2], leaves[3])];
      const proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(await indexedMT.getRoot());
      expect(proof.existence).to.be.false;
      expect(proof.index).to.be.eq(index);
      expect(proof.value).to.be.eq(values[Number(index)]);
      expect(proof.nextLeafIndex).to.be.eq(nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedSiblings);
    });

    it("should get exception if pass invalid index", async () => {
      const index = 1n;
      const value = 5n;

      await expect(indexedMT.getProof(index, value))
        .to.be.revertedWithCustomError(indexedMT, "InvalidProofIndex")
        .withArgs(index, value);
    });
  });

  describe("verifyProof", () => {
    const values: bigint[] = [0n, 10n, 20n, 30n, 40n, 50n];
    let leaves: string[] = [];

    beforeEach("setup", async () => {
      for (let i = 0; i < values.length; i++) {
        leaves.push(
          hashLeaf(BigInt(i), encodeBytes32Value(values[i]), i == values.length - 1 ? 0n : BigInt(i + 1), true),
        );

        if (i > 0) {
          await indexedMT.addUint(values[i], i - 1);
        }
      }
    });

    afterEach("clean", async () => {
      leaves = [];
    });

    it("should correctly verify inclusion proofs", async () => {
      let index = 1n;
      let proof = await indexedMT.getProof(index, values[Number(index)]);

      expect(
        await indexedMT.verifyProof({
          root: proof.root,
          existence: proof.existence,
          siblings: [...proof.siblings],
          index: proof.index,
          value: proof.value,
          nextLeafIndex: proof.nextLeafIndex,
        }),
      ).to.be.true;

      index = 2n;
      proof = await indexedMT.getProof(index, values[Number(index)]);

      expect(
        await indexedMT.verifyProof({
          root: proof.root,
          existence: proof.existence,
          siblings: [...proof.siblings],
          index: proof.index,
          value: proof.value,
          nextLeafIndex: proof.nextLeafIndex,
        }),
      ).to.be.true;

      index = 5n;
      proof = await indexedMT.getProof(index, values[Number(index)]);

      expect(
        await indexedMT.verifyProof({
          root: proof.root,
          existence: proof.existence,
          siblings: [...proof.siblings],
          index: proof.index,
          value: proof.value,
          nextLeafIndex: proof.nextLeafIndex,
        }),
      ).to.be.true;
    });
  });
});
