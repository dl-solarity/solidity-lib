import { expect } from "chai";
import { ethers } from "hardhat";

import {
  getBlocksDataFilePath,
  getRandomBlockHeaderData,
  checkBlockHeaderData,
  checkBlockHeaderDataDiffEncodings,
} from "@/test/helpers/block-helpers";

import { Reverter } from "@/test/helpers/reverter";

import { BlockHeaderMock } from "@ethers-v6";
import { reverseBytes } from "@/test/helpers/bytes-helper";

describe("BlockHeader", () => {
  const reverter = new Reverter();

  let blockHeaderLib: BlockHeaderMock;

  let blocksDataFilePath: string;

  before(async () => {
    blockHeaderLib = await ethers.deployContract("BlockHeaderMock");

    blocksDataFilePath = getBlocksDataFilePath("headers_1_10000.json");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#parseBlockHeaderData", () => {
    it("should correctly parse block header data to big-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(blocksDataFilePath, 1, 10000);
        const parsedResult = await blockHeaderLib.parseBlockHeaderData(blockData.rawHeader, true);

        expect(parsedResult[1]).to.be.eq(blockData.blockHash);
        checkBlockHeaderData(parsedResult[0], blockData);
      }
    });

    it("should correctly parse block header data to little-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(blocksDataFilePath, 1, 10000);
        const parsedResult = await blockHeaderLib.parseBlockHeaderData(blockData.rawHeader, false);

        expect(parsedResult[1]).to.be.eq(reverseBytes(blockData.blockHash));
        checkBlockHeaderDataDiffEncodings(parsedResult[0], blockData);
      }
    });

    it("should get exception if try to pass invalid block header raw data", async () => {
      await expect(
        blockHeaderLib.parseBlockHeaderData(
          "0x01000000006fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e61bc6649ffff001d01e36299",
          false,
        ),
      ).to.be.revertedWithCustomError(blockHeaderLib, "InvalidBlockHeaderDataLength");
    });
  });

  describe("#toRawBytes", () => {
    it("should correctly convert block header data to the raw bytes", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(blocksDataFilePath, 1, 10000);

        expect(
          await blockHeaderLib.toRawBytes({
            prevBlockHash: blockData.parsedBlockHeader.previousblockhash,
            merkleRoot: blockData.parsedBlockHeader.merkleroot,
            version: blockData.parsedBlockHeader.version,
            time: blockData.parsedBlockHeader.time,
            nonce: blockData.parsedBlockHeader.nonce,
            bits: blockData.parsedBlockHeader.bits,
          }),
        ).to.be.eq(blockData.rawHeader);
      }
    });
  });
});
