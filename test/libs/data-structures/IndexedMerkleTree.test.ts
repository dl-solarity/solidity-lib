import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { IndexedMerkleTreeMock } from "@ethers-v6";

import { IndexedMerkleTree, encodeBytes32Value, hashIndexedLeaf } from "@/test/helpers/indexed-merkle-tree.ts";

const { ethers, networkHelpers } = await hre.network.connect();

describe("IndexedMerkleTree", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const LEAVES_LEVEL = 0n;

  let indexedMT: IndexedMerkleTreeMock;

  function getRandomIntInclusive(min: number, max: number): number {
    min = Math.ceil(min);
    max = Math.floor(max);

    return Math.floor(Math.random() * (max - min + 1)) + min;
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
      const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
      const zeroLeafHash = hashIndexedLeaf({
        index: 0n,
        isActive: true,
        nextIndex: 0n,
        value: ethers.ZeroHash,
      });

      expect(await indexedMT.getRoot()).to.be.eq(zeroLeafHash);
      expect(await indexedMT.getRoot()).to.be.eq(localIndexedMerkleTree.getRoot());
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

      const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();

      for (let i = 0; i < count; ++i) {
        const currentIndex = startIndex + BigInt(i);

        await indexedMT.addUint(value, lowLeafIndex);
        localIndexedMerkleTree.add(encodeBytes32Value(value));

        const leafData = await indexedMT.getLeafData(currentIndex);

        expect(leafData.value).to.be.eq(value);
        expect(leafData.nextLeafIndex).to.be.eq(0n);

        const leafHash = hashIndexedLeaf({
          index: currentIndex,
          value: encodeBytes32Value(value),
          nextIndex: 0n,
          isActive: true,
        });
        expect(await indexedMT.getNodeHash(currentIndex, LEAVES_LEVEL)).to.be.eq(leafHash);

        const lowLeafData = await indexedMT.getLeafData(lowLeafIndex);

        expect(lowLeafData.value).to.be.eq(lowLeafValue);
        expect(lowLeafData.nextLeafIndex).to.be.eq(currentIndex);

        const lowLeafNewHash = hashIndexedLeaf({
          index: lowLeafIndex,
          value: encodeBytes32Value(lowLeafValue),
          nextIndex: currentIndex,
          isActive: true,
        });
        expect(await indexedMT.getNodeHash(lowLeafIndex, LEAVES_LEVEL)).to.be.eq(lowLeafNewHash);

        lowLeafIndex = currentIndex;
        lowLeafValue = value;
        value *= 2n;

        expect(await indexedMT.getRoot()).to.be.eq(localIndexedMerkleTree.getRoot());
      }

      const expectedLevelsCount = Math.ceil(Math.log2(count + 1)) + 1;

      expect(await indexedMT.getTreeLevels()).to.be.eq(expectedLevelsCount);
    });

    it("should correctly add 100 random elements", async () => {
      const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
      const elementsCount = 100n;

      for (let i = 0; i < elementsCount; ++i) {
        const currentValue = ethers.hexlify(ethers.randomBytes(32));
        const lowLeafIndex = localIndexedMerkleTree.getLowLeafIndex(currentValue);

        const expectedNextLeafIndex = localIndexedMerkleTree.getLeafData(lowLeafIndex).nextLeafIndex;

        const index = localIndexedMerkleTree.add(currentValue, lowLeafIndex);
        await indexedMT.addUint(BigInt(currentValue), lowLeafIndex);

        expect(await indexedMT.getRoot()).to.be.eq(localIndexedMerkleTree.getRoot());

        const leafData = await indexedMT.getLeafData(index);

        expect(leafData.value).to.be.eq(currentValue);
        expect(leafData.nextLeafIndex).to.be.eq(expectedNextLeafIndex);

        expect((await indexedMT.getLeafData(lowLeafIndex)).nextLeafIndex).to.be.eq(index);
      }
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
    let localIndexedMerkleTree: IndexedMerkleTree;

    beforeEach("setup", async () => {
      localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();

      for (let i = 1; i < values.length; i++) {
        localIndexedMerkleTree.add(encodeBytes32Value(values[i]));

        await indexedMT.addUint(values[i], i - 1);
      }
    });

    it("should return correct inclusion proof", async () => {
      let index = 2n;
      let value = 20n;
      let expectedProof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(value));
      let proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(expectedProof.root);
      expect(proof.existence).to.be.true;
      expect(proof.existence).to.be.eq(expectedProof.existence);
      expect(proof.index).to.be.eq(expectedProof.index);
      expect(proof.value).to.be.eq(expectedProof.value);
      expect(proof.nextLeafIndex).to.be.eq(expectedProof.nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedProof.siblings);

      index = 1n;
      value = 10n;
      expectedProof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(value));
      proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(expectedProof.root);
      expect(proof.existence).to.be.true;
      expect(proof.existence).to.be.eq(expectedProof.existence);
      expect(proof.index).to.be.eq(expectedProof.index);
      expect(proof.value).to.be.eq(expectedProof.value);
      expect(proof.nextLeafIndex).to.be.eq(expectedProof.nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedProof.siblings);
    });

    it("should return correct inclusion proofs with the random tree elements", async () => {
      const newIndexedMT = await ethers.deployContract("IndexedMerkleTreeMock");
      const newLocalIndexedMT = IndexedMerkleTree.buildMerkleTree();

      await newIndexedMT.initializeUintTree();

      const valuesCount = 100n;
      const values = [];

      for (let i = 0; i < valuesCount; ++i) {
        const currentValue = ethers.hexlify(ethers.randomBytes(32));
        const lowLeafIndex = newLocalIndexedMT.getLowLeafIndex(currentValue);

        newLocalIndexedMT.add(currentValue, lowLeafIndex);
        await newIndexedMT.addUint(BigInt(currentValue), lowLeafIndex);

        values.push(currentValue);
      }

      const proofsCount = 100n;

      for (let i = 0; i < proofsCount; i++) {
        const randIndex = getRandomIntInclusive(0, 99);
        const valueToProve = values[randIndex];

        const index = newLocalIndexedMT.getLeafIndex(valueToProve);

        const expectedProof = newLocalIndexedMT.getProof(index, valueToProve);
        const proof = await newIndexedMT.getProof(index, valueToProve);

        expect(proof.root).to.be.eq(expectedProof.root);
        expect(proof.existence).to.be.true;
        expect(proof.existence).to.be.eq(expectedProof.existence);
        expect(proof.index).to.be.eq(expectedProof.index);
        expect(proof.value).to.be.eq(expectedProof.value);
        expect(proof.nextLeafIndex).to.be.eq(expectedProof.nextLeafIndex);
        expect(proof.siblings).to.be.deep.eq(expectedProof.siblings);
      }
    });

    it("should return correct exclusion proof", async () => {
      const index = 1n;
      const value = 15n;
      const expectedProof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(value));
      const proof = await indexedMT.getProof(index, value);

      expect(proof.root).to.be.eq(await indexedMT.getRoot());
      expect(proof.existence).to.be.false;
      expect(proof.existence).to.be.eq(expectedProof.existence);
      expect(proof.index).to.be.eq(expectedProof.index);
      expect(proof.value).to.be.eq(expectedProof.value);
      expect(proof.nextLeafIndex).to.be.eq(expectedProof.nextLeafIndex);
      expect(proof.siblings).to.be.deep.eq(expectedProof.siblings);
    });

    it("should return correct exclusion proofs with the random tree elements", async () => {
      const newIndexedMT = await ethers.deployContract("IndexedMerkleTreeMock");
      const newLocalIndexedMT = IndexedMerkleTree.buildMerkleTree();

      await newIndexedMT.initializeUintTree();

      const valuesCount = 100n;
      const values = [];

      for (let i = 0; i < valuesCount; ++i) {
        const currentValue = ethers.hexlify(ethers.randomBytes(32));
        const lowLeafIndex = newLocalIndexedMT.getLowLeafIndex(currentValue);

        newLocalIndexedMT.add(currentValue, lowLeafIndex);
        await newIndexedMT.addUint(BigInt(currentValue), lowLeafIndex);

        values.push(currentValue);
      }

      const proofsCount = 100n;

      for (let i = 0; i < proofsCount; i++) {
        let valueToProve: string;

        do {
          valueToProve = ethers.hexlify(ethers.randomBytes(32));
        } while (values.includes(valueToProve));

        const index = newLocalIndexedMT.getLowLeafIndex(valueToProve);

        const expectedProof = newLocalIndexedMT.getProof(index, valueToProve);
        const proof = await newIndexedMT.getProof(index, valueToProve);

        expect(proof.root).to.be.eq(expectedProof.root);
        expect(proof.existence).to.be.false;
        expect(proof.existence).to.be.eq(expectedProof.existence);
        expect(proof.index).to.be.eq(expectedProof.index);
        expect(proof.value).to.be.eq(expectedProof.value);
        expect(proof.nextLeafIndex).to.be.eq(expectedProof.nextLeafIndex);
        expect(proof.siblings).to.be.deep.eq(expectedProof.siblings);
      }
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
    let localIndexedMerkleTree: IndexedMerkleTree;

    beforeEach("setup", async () => {
      localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();

      for (let i = 1; i < values.length; i++) {
        const lowIndex = localIndexedMerkleTree.getLowLeafIndex(encodeBytes32Value(values[i]));
        localIndexedMerkleTree.add(encodeBytes32Value(values[i]));

        await indexedMT.addUint(values[i], lowIndex);
      }
    });

    it("should correctly verify inclusion proofs", async () => {
      let index = 1n;
      let proof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(values[Number(index)]));

      expect(await indexedMT.verifyProof(proof)).to.be.true;

      index = 2n;
      proof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(values[Number(index)]));

      expect(await indexedMT.verifyProof(proof)).to.be.true;

      index = 5n;
      proof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(values[Number(index)]));

      expect(await indexedMT.verifyProof(proof)).to.be.true;
    });

    it("should correctly verify inclusion proofs with the random tree elements", async () => {
      const newIndexedMT = await ethers.deployContract("IndexedMerkleTreeMock");
      const newLocalIndexedMT = IndexedMerkleTree.buildMerkleTree();

      await newIndexedMT.initializeUintTree();

      const valuesCount = 100n;
      const values = [];

      for (let i = 0; i < valuesCount; ++i) {
        const currentValue = ethers.hexlify(ethers.randomBytes(32));
        const lowLeafIndex = newLocalIndexedMT.getLowLeafIndex(currentValue);

        newLocalIndexedMT.add(currentValue, lowLeafIndex);
        await newIndexedMT.addUint(BigInt(currentValue), lowLeafIndex);

        values.push(currentValue);
      }

      const proofsCount = 100n;

      for (let i = 0; i < proofsCount; i++) {
        const randIndex = getRandomIntInclusive(0, 99);
        const valueToProve = values[randIndex];

        const index = newLocalIndexedMT.getLeafIndex(valueToProve);
        const proof = newLocalIndexedMT.getProof(index, valueToProve);

        expect(await newIndexedMT.verifyProof(proof)).to.be.true;
      }
    });

    it("should correctly verify exclusion proofs with the random tree elements", async () => {
      const newIndexedMT = await ethers.deployContract("IndexedMerkleTreeMock");
      const newLocalIndexedMT = IndexedMerkleTree.buildMerkleTree();

      await newIndexedMT.initializeUintTree();

      const valuesCount = 100n;
      const values = [];

      for (let i = 0; i < valuesCount; ++i) {
        const currentValue = ethers.hexlify(ethers.randomBytes(32));
        const lowLeafIndex = newLocalIndexedMT.getLowLeafIndex(currentValue);

        newLocalIndexedMT.add(currentValue, lowLeafIndex);
        await newIndexedMT.addUint(BigInt(currentValue), lowLeafIndex);

        values.push(currentValue);
      }

      const proofsCount = 100n;

      for (let i = 0; i < proofsCount; i++) {
        let valueToProve: string;

        do {
          valueToProve = ethers.hexlify(ethers.randomBytes(32));
        } while (values.includes(valueToProve));

        const index = newLocalIndexedMT.getLowLeafIndex(valueToProve);
        const proof = newLocalIndexedMT.getProof(index, valueToProve);

        expect(await newIndexedMT.verifyProof(proof)).to.be.true;
      }
    });
  });
});
