import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { IndexedMerkleTreeMock } from "@ethers-v6";

import { IndexedMerkleTree as IndexedMerkleTreeLib } from "../../../generated-types/ethers/mock/libs/data-structures/IndexedMerkleTreeMock.ts";
import { IndexedMerkleTree, Proof, encodeBytes32Value, hashIndexedLeaf } from "@/test/helpers/indexed-merkle-tree.ts";

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

  function compareProofs(
    contractProof: IndexedMerkleTreeLib.ProofStructOutput,
    localProof: Proof,
    expectedExistence: boolean,
  ) {
    expect(contractProof.root).to.be.eq(localProof.root);
    expect(contractProof.existence).to.be.eq(expectedExistence);
    expect(contractProof.existence).to.be.eq(localProof.existence);
    expect(contractProof.index).to.be.eq(localProof.index);
    expect(contractProof.value).to.be.eq(localProof.value);
    expect(contractProof.nextLeafIndex).to.be.eq(localProof.nextLeafIndex);
    expect(contractProof.siblings).to.be.deep.eq(localProof.siblings);
  }

  function encodeAddressValue(address: string): string {
    return ethers.AbiCoder.defaultAbiCoder().encode(["address"], [address]);
  }

  before("setup", async () => {
    indexedMT = await ethers.deployContract("IndexedMerkleTreeMock");

    await reverter.snapshot();
  });

  afterEach("cleanup", async () => {
    await reverter.revert();
  });

  describe("UintIndexedMerkleTree", () => {
    beforeEach("setup", async () => {
      await indexedMT.initializeUintTree();
    });

    describe("initialize", () => {
      it("should correctly initialize UintIndexedMerkleTree", async () => {
        const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
        const zeroLeafHash = hashIndexedLeaf({
          index: 0n,
          isActive: true,
          nextIndex: 0n,
          value: ethers.ZeroHash,
        });

        expect(await indexedMT.getRootUint()).to.be.eq(zeroLeafHash);
        expect(await indexedMT.getRootUint()).to.be.eq(localIndexedMerkleTree.getRoot());
        expect(await indexedMT.getTreeLevelsUint()).to.be.eq(1);
        expect(await indexedMT.getLeavesCountUint()).to.be.eq(1);
        expect(await indexedMT.getNodeHashUint(0, LEAVES_LEVEL)).to.be.eq(zeroLeafHash);
      });

      it("should get exception if try to initialize twice", async () => {
        await expect(indexedMT.initializeUintTree()).to.be.revertedWithCustomError(
          indexedMT,
          "IndexedMerkleTreeAlreadyInitialized",
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

          const leafData = await indexedMT.getLeafDataUint(currentIndex);

          expect(leafData.value).to.be.eq(value);
          expect(leafData.nextLeafIndex).to.be.eq(0n);

          const leafHash = hashIndexedLeaf({
            index: currentIndex,
            value: encodeBytes32Value(value),
            nextIndex: 0n,
            isActive: true,
          });
          expect(await indexedMT.getNodeHashUint(currentIndex, LEAVES_LEVEL)).to.be.eq(leafHash);

          const lowLeafData = await indexedMT.getLeafDataUint(lowLeafIndex);

          expect(lowLeafData.value).to.be.eq(lowLeafValue);
          expect(lowLeafData.nextLeafIndex).to.be.eq(currentIndex);

          const lowLeafNewHash = hashIndexedLeaf({
            index: lowLeafIndex,
            value: encodeBytes32Value(lowLeafValue),
            nextIndex: currentIndex,
            isActive: true,
          });
          expect(await indexedMT.getNodeHashUint(lowLeafIndex, LEAVES_LEVEL)).to.be.eq(lowLeafNewHash);

          lowLeafIndex = currentIndex;
          lowLeafValue = value;
          value *= 2n;

          expect(await indexedMT.getRootUint()).to.be.eq(localIndexedMerkleTree.getRoot());
        }

        const expectedLevelsCount = Math.ceil(Math.log2(count + 1)) + 1;

        expect(await indexedMT.getTreeLevelsUint()).to.be.eq(expectedLevelsCount);
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

          expect(await indexedMT.getRootUint()).to.be.eq(localIndexedMerkleTree.getRoot());

          const leafData = await indexedMT.getLeafDataUint(index);

          expect(leafData.value).to.be.eq(currentValue);
          expect(leafData.nextLeafIndex).to.be.eq(expectedNextLeafIndex);

          expect((await indexedMT.getLeafDataUint(lowLeafIndex)).nextLeafIndex).to.be.eq(index);
        }

        expect(await indexedMT.getLevelNodesCountUint(LEAVES_LEVEL)).to.be.eq(elementsCount + 1n);
      });

      it("should get exception if pass invalid low leaf index", async () => {
        await indexedMT.addUint(10n, 0n);
        await indexedMT.addUint(20n, 1n);

        await expect(indexedMT.addUint(5n, 1n)).to.be.revertedWithCustomError(indexedMT, "InvalidLowLeaf");
        await expect(indexedMT.addUint(25n, 1n)).to.be.revertedWithCustomError(indexedMT, "InvalidLowLeaf");
      });

      it("should get exception if the tree is not initialized", async () => {
        const newIndexedMT = await ethers.deployContract("IndexedMerkleTreeMock");

        await expect(newIndexedMT.addUint(10n, 0n)).to.be.revertedWithCustomError(
          newIndexedMT,
          "IndexedMerkleTreeNotInitialized",
        );
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
        let proof = await indexedMT.getProofUint(index, value);

        compareProofs(proof, expectedProof, true);

        index = 1n;
        value = 10n;
        expectedProof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(value));
        proof = await indexedMT.getProofUint(index, value);

        compareProofs(proof, expectedProof, true);
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
          const proof = await newIndexedMT.getProofUint(index, valueToProve);

          compareProofs(proof, expectedProof, true);
        }
      });

      it("should return correct exclusion proof", async () => {
        const index = 1n;
        const value = 15n;
        const expectedProof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(value));
        const proof = await indexedMT.getProofUint(index, value);

        compareProofs(proof, expectedProof, false);
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
          const proof = await newIndexedMT.getProofUint(index, valueToProve);

          compareProofs(proof, expectedProof, false);
        }
      });

      it("should get exception if pass invalid index", async () => {
        const index = 1n;
        const value = 5n;

        await expect(indexedMT.getProofUint(index, value))
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

        expect(await indexedMT.verifyProofUint(proof)).to.be.true;

        index = 2n;
        proof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(values[Number(index)]));

        expect(await indexedMT.verifyProofUint(proof)).to.be.true;

        index = 5n;
        proof = localIndexedMerkleTree.getProof(index, encodeBytes32Value(values[Number(index)]));

        expect(await indexedMT.verifyProofUint(proof)).to.be.true;

        expect(await indexedMT.processProof(proof)).to.be.eq(localIndexedMerkleTree.getRoot());
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

          expect(await newIndexedMT.verifyProofUint(proof)).to.be.true;
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

          expect(await newIndexedMT.verifyProofUint(proof)).to.be.true;
        }
      });
    });

    describe("getters", () => {
      it("should get exception if pass invalid index", async () => {
        const invalidIndex = 120n;

        await expect(indexedMT.getLeafDataUint(invalidIndex))
          .to.be.revertedWithCustomError(indexedMT, "IndexOutOfBounds")
          .withArgs(invalidIndex, LEAVES_LEVEL);
      });
    });
  });

  describe("Bytes32IndexedMerkleTree", () => {
    beforeEach("setup", async () => {
      await indexedMT.initializeBytes32Tree();
    });

    describe("initialize", () => {
      it("should correctly initialize Bytes32IndexedMerkleTree", async () => {
        const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
        const zeroLeafHash = hashIndexedLeaf({
          index: 0n,
          isActive: true,
          nextIndex: 0n,
          value: ethers.ZeroHash,
        });

        expect(await indexedMT.getRootBytes32()).to.be.eq(zeroLeafHash);
        expect(await indexedMT.getRootBytes32()).to.be.eq(localIndexedMerkleTree.getRoot());
        expect(await indexedMT.getTreeLevelsBytes32()).to.be.eq(1);
        expect(await indexedMT.getLeavesCountBytes32()).to.be.eq(1);
        expect(await indexedMT.getNodeHashBytes32(0, LEAVES_LEVEL)).to.be.eq(zeroLeafHash);
      });

      it("should get exception if try to initialize twice", async () => {
        await expect(indexedMT.initializeBytes32Tree()).to.be.revertedWithCustomError(
          indexedMT,
          "IndexedMerkleTreeAlreadyInitialized",
        );
      });
    });

    describe("add", () => {
      it("should correctly add 100 random elements", async () => {
        const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
        const elementsCount = 100n;

        for (let i = 0; i < elementsCount; ++i) {
          const currentValue = ethers.hexlify(ethers.randomBytes(32));
          const lowLeafIndex = localIndexedMerkleTree.getLowLeafIndex(currentValue);

          const expectedNextLeafIndex = localIndexedMerkleTree.getLeafData(lowLeafIndex).nextLeafIndex;

          const index = localIndexedMerkleTree.add(currentValue, lowLeafIndex);
          await indexedMT.addBytes32(currentValue, lowLeafIndex);

          expect(await indexedMT.getRootBytes32()).to.be.eq(localIndexedMerkleTree.getRoot());

          const leafData = await indexedMT.getLeafDataBytes32(index);

          expect(leafData.value).to.be.eq(currentValue);
          expect(leafData.nextLeafIndex).to.be.eq(expectedNextLeafIndex);

          expect((await indexedMT.getLeafDataBytes32(lowLeafIndex)).nextLeafIndex).to.be.eq(index);
        }

        expect(await indexedMT.getLevelNodesCountBytes32(LEAVES_LEVEL)).to.be.eq(elementsCount + 1n);
      });
    });

    describe("getProof", () => {
      it("should return correct exclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const currentValue = ethers.hexlify(ethers.randomBytes(32));
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(currentValue);

          localIndexedMT.add(currentValue, lowLeafIndex);
          await indexedMT.addBytes32(currentValue, lowLeafIndex);

          values.push(currentValue);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          let valueToProve: string;

          do {
            valueToProve = ethers.hexlify(ethers.randomBytes(32));
          } while (values.includes(valueToProve));

          const index = localIndexedMT.getLowLeafIndex(valueToProve);

          const expectedProof = localIndexedMT.getProof(index, valueToProve);
          const proof = await indexedMT.getProofBytes32(index, valueToProve);

          compareProofs(proof, expectedProof, false);
        }
      });
    });

    describe("verifyProof", () => {
      it("should correctly verify inclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const currentValue = ethers.hexlify(ethers.randomBytes(32));
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(currentValue);

          localIndexedMT.add(currentValue, lowLeafIndex);
          await indexedMT.addBytes32(currentValue, lowLeafIndex);

          values.push(currentValue);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          const randIndex = getRandomIntInclusive(0, 99);
          const valueToProve = values[randIndex];

          const index = localIndexedMT.getLeafIndex(valueToProve);
          const proof = localIndexedMT.getProof(index, valueToProve);

          expect(await indexedMT.verifyProofBytes32(proof)).to.be.true;
        }
      });

      it("should correctly verify exclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const currentValue = ethers.hexlify(ethers.randomBytes(32));
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(currentValue);

          localIndexedMT.add(currentValue, lowLeafIndex);
          await indexedMT.addBytes32(currentValue, lowLeafIndex);

          values.push(currentValue);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          let valueToProve: string;

          do {
            valueToProve = ethers.hexlify(ethers.randomBytes(32));
          } while (values.includes(valueToProve));

          const index = localIndexedMT.getLowLeafIndex(valueToProve);
          const proof = localIndexedMT.getProof(index, valueToProve);

          expect(await indexedMT.verifyProofBytes32(proof)).to.be.true;
        }
      });
    });
  });

  describe("AddressIndexedMerkleTree", () => {
    beforeEach("setup", async () => {
      await indexedMT.initializeAddressTree();
    });

    describe("initialize", () => {
      it("should correctly initialize AddressIndexedMerkleTree", async () => {
        const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
        const zeroLeafHash = hashIndexedLeaf({
          index: 0n,
          isActive: true,
          nextIndex: 0n,
          value: ethers.ZeroHash,
        });

        expect(await indexedMT.getRootAddress()).to.be.eq(zeroLeafHash);
        expect(await indexedMT.getRootAddress()).to.be.eq(localIndexedMerkleTree.getRoot());
        expect(await indexedMT.getTreeLevelsAddress()).to.be.eq(1);
        expect(await indexedMT.getLeavesCountAddress()).to.be.eq(1);
        expect(await indexedMT.getNodeHashAddress(0, LEAVES_LEVEL)).to.be.eq(zeroLeafHash);
      });

      it("should get exception if try to initialize twice", async () => {
        await expect(indexedMT.initializeAddressTree()).to.be.revertedWithCustomError(
          indexedMT,
          "IndexedMerkleTreeAlreadyInitialized",
        );
      });
    });

    describe("add", () => {
      it("should correctly add 100 random elements", async () => {
        const localIndexedMerkleTree = IndexedMerkleTree.buildMerkleTree();
        const elementsCount = 100n;

        for (let i = 0; i < elementsCount; ++i) {
          const randomAddress = ethers.hexlify(ethers.randomBytes(20));
          const encodedAddress = encodeAddressValue(randomAddress);
          const lowLeafIndex = localIndexedMerkleTree.getLowLeafIndex(encodedAddress);

          const expectedNextLeafIndex = localIndexedMerkleTree.getLeafData(lowLeafIndex).nextLeafIndex;

          const index = localIndexedMerkleTree.add(encodedAddress, lowLeafIndex);
          await indexedMT.addAddress(randomAddress, lowLeafIndex);

          expect(await indexedMT.getRootAddress()).to.be.eq(localIndexedMerkleTree.getRoot());

          const leafData = await indexedMT.getLeafDataAddress(index);

          expect(leafData.value).to.be.eq(encodedAddress);
          expect(leafData.nextLeafIndex).to.be.eq(expectedNextLeafIndex);

          expect((await indexedMT.getLeafDataAddress(lowLeafIndex)).nextLeafIndex).to.be.eq(index);
        }

        expect(await indexedMT.getLevelNodesCountAddress(LEAVES_LEVEL)).to.be.eq(elementsCount + 1n);
      });
    });

    describe("getProof", () => {
      it("should return correct exclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const randomAddress = ethers.hexlify(ethers.randomBytes(20));
          const encodedAddress = encodeAddressValue(randomAddress);
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(encodedAddress);

          localIndexedMT.add(encodedAddress, lowLeafIndex);
          await indexedMT.addAddress(randomAddress, lowLeafIndex);

          values.push(randomAddress);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          let addressToProve: string;

          do {
            addressToProve = ethers.hexlify(ethers.randomBytes(20));
          } while (values.includes(addressToProve));

          const encodedAddressToProve = encodeAddressValue(addressToProve);

          const index = localIndexedMT.getLowLeafIndex(encodedAddressToProve);

          const expectedProof = localIndexedMT.getProof(index, encodedAddressToProve);
          const proof = await indexedMT.getProofAddress(index, addressToProve);

          compareProofs(proof, expectedProof, false);
        }
      });
    });

    describe("verifyProof", () => {
      it("should correctly verify inclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const randomAddress = ethers.hexlify(ethers.randomBytes(20));
          const encodedAddress = encodeAddressValue(randomAddress);
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(encodedAddress);

          localIndexedMT.add(encodedAddress, lowLeafIndex);
          await indexedMT.addAddress(randomAddress, lowLeafIndex);

          values.push(randomAddress);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          const randIndex = getRandomIntInclusive(0, 99);
          const addressToProve = values[randIndex];
          const encodedAddressToProve = encodeAddressValue(addressToProve);

          const index = localIndexedMT.getLeafIndex(encodedAddressToProve);
          const proof = localIndexedMT.getProof(index, encodedAddressToProve);

          expect(await indexedMT.verifyProofAddress(proof)).to.be.true;
        }
      });

      it("should correctly verify exclusion proofs with the random tree elements", async () => {
        const localIndexedMT = IndexedMerkleTree.buildMerkleTree();

        const valuesCount = 100n;
        const values = [];

        for (let i = 0; i < valuesCount; ++i) {
          const randomAddress = ethers.hexlify(ethers.randomBytes(20));
          const encodedAddress = encodeAddressValue(randomAddress);
          const lowLeafIndex = localIndexedMT.getLowLeafIndex(encodedAddress);

          localIndexedMT.add(encodedAddress, lowLeafIndex);
          await indexedMT.addAddress(randomAddress, lowLeafIndex);

          values.push(randomAddress);
        }

        const proofsCount = 100n;

        for (let i = 0; i < proofsCount; i++) {
          let addressToProve: string;

          do {
            addressToProve = ethers.hexlify(ethers.randomBytes(20));
          } while (values.includes(addressToProve));

          const encodedAddressToProve = encodeAddressValue(addressToProve);

          const index = localIndexedMT.getLowLeafIndex(encodedAddressToProve);
          const proof = localIndexedMT.getProof(index, encodedAddressToProve);

          expect(await indexedMT.verifyProofAddress(proof)).to.be.true;
        }
      });
    });
  });
});
