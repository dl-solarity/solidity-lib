import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { IndexedMerkleTreeMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("IndexedMerkleTree", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const LEAVES_LEVEL = 0n;

  let indexedMT: IndexedMerkleTreeMock;

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
      const zeroLeafHash = hashLeaf(0n, ethers.ZeroHash, 0n, false);

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
});
