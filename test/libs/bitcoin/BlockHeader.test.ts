import { expect } from "chai";
import hre from "hardhat";

import {
  Reverter,
  checkBlockHeaderDataInBE,
  checkBlockHeaderDataInLE,
  getBlockHeaderData,
  getBlocksDataFilePath,
  reverseBytes,
} from "@test-helpers";

import { BlockHeaderMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("BlockHeader", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let blockHeaderLib: BlockHeaderMock;

  let blocksDataFilePath: string;

  before("setup", async () => {
    blockHeaderLib = await ethers.deployContract("BlockHeaderMock");

    blocksDataFilePath = getBlocksDataFilePath("headers_814991_815000.json");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#parseBlockHeader", () => {
    it("should correctly parse block header data to big-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getBlockHeaderData(blocksDataFilePath, 814991 + i);
        const parsedResult = await blockHeaderLib.parseBlockHeader(blockData.rawHeader, true);

        expect(parsedResult[1]).to.be.eq(blockData.blockHash);
        checkBlockHeaderDataInBE(parsedResult[0], blockData);
      }
    });

    it("should correctly parse block header data to little-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getBlockHeaderData(blocksDataFilePath, 814991 + i);
        const parsedResult = await blockHeaderLib.parseBlockHeader(blockData.rawHeader, false);

        expect(parsedResult[1]).to.be.eq(reverseBytes(blockData.blockHash));
        checkBlockHeaderDataInLE(parsedResult[0], blockData);
      }
    });

    it("should get exception if try to pass invalid block header raw data", async () => {
      await expect(
        blockHeaderLib.parseBlockHeader(
          "0x01000000006fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e61bc6649ffff001d01e36299",
          false,
        ),
      ).to.be.revertedWithCustomError(blockHeaderLib, "InvalidBlockHeaderDataLength");
    });
  });

  describe("#toRawBytes", () => {
    it("should correctly convert block header data to the raw bytes from big-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getBlockHeaderData(blocksDataFilePath, 814991 + i);

        expect(
          await blockHeaderLib.toRawBytes(
            {
              prevBlockHash: blockData.parsedBlockHeader.previousblockhash,
              merkleRoot: blockData.parsedBlockHeader.merkleroot,
              version: blockData.parsedBlockHeader.version,
              time: blockData.parsedBlockHeader.time,
              nonce: blockData.parsedBlockHeader.nonce,
              bits: blockData.parsedBlockHeader.bits,
            },
            true,
          ),
        ).to.be.eq(blockData.rawHeader);
      }
    });

    it("should correctly convert block header data to the raw bytes from little-endian format", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getBlockHeaderData(blocksDataFilePath, 814991 + i);
        const parsed = await blockHeaderLib.parseBlockHeader(blockData.rawHeader, false);

        expect(
          await blockHeaderLib.toRawBytes(
            {
              prevBlockHash: parsed[0].prevBlockHash,
              merkleRoot: parsed[0].merkleRoot,
              version: parsed[0].version,
              time: parsed[0].time,
              nonce: parsed[0].nonce,
              bits: parsed[0].bits,
            },
            false,
          ),
        ).to.be.eq(blockData.rawHeader);
      }
    });
  });
});
