import { expect } from "chai";
import { ethers } from "hardhat";

import { Reverter } from "@/test/helpers/reverter";

import { getBlocksDataFilePath, getRandomBlockHeaderData, getBlockHeaderData } from "@/test/helpers/block-helpers";

import { TargetsHelperMock } from "@ethers-v6";
import {
  bitsToTarget,
  calculateWork,
  DIFFICULTY_ADJUSTMENT_INTERVAL,
  INITIAL_TARGET,
} from "@/test/helpers/targets-helper";

describe("TargetsHelper", () => {
  const reverter = new Reverter();

  let targetsHelperLib: TargetsHelperMock;

  let firstBlocksDataFilePath: string;
  let newestBlocksDataFilePath: string;

  before(async () => {
    targetsHelperLib = await ethers.deployContract("TargetsHelperMock");

    firstBlocksDataFilePath = getBlocksDataFilePath("headers_1_10000.json");
    newestBlocksDataFilePath = getBlocksDataFilePath("headers_800352_815000.json");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#countNewTarget", () => {
    it("should correctly count new target for the first epochs", async () => {
      const firstEpochBlockData = getBlockHeaderData(firstBlocksDataFilePath, 1);
      const lastEpochBlockData = getBlockHeaderData(firstBlocksDataFilePath, DIFFICULTY_ADJUSTMENT_INTERVAL);

      const actualPassedTime =
        BigInt(lastEpochBlockData.parsedBlockHeader.time) - BigInt(firstEpochBlockData.parsedBlockHeader.time);

      expect(await targetsHelperLib.countNewTarget(INITIAL_TARGET, actualPassedTime)).to.be.eq(INITIAL_TARGET);
    });

    it("should correctly count new target for the newest epochs", async () => {
      const startEpochHeight = 800352;

      const firstEpochBlockData = getBlockHeaderData(newestBlocksDataFilePath, startEpochHeight);
      const lastEpochBlockData = getBlockHeaderData(
        newestBlocksDataFilePath,
        startEpochHeight + DIFFICULTY_ADJUSTMENT_INTERVAL - 1,
      );

      const actualPassedTime =
        BigInt(lastEpochBlockData.parsedBlockHeader.time) - BigInt(firstEpochBlockData.parsedBlockHeader.time);

      const expectedTarget = "0x000000000000000000055f5b227e90718f8fa9146ba3155d3b44afe57745ec49";

      expect(
        await targetsHelperLib.countNewTarget(
          bitsToTarget(lastEpochBlockData.parsedBlockHeader.bits),
          actualPassedTime,
        ),
      ).to.be.eq(expectedTarget);
    });
  });

  describe("#countNewRoundedTarget", async () => {
    it("should correctly count new target for the first epochs", async () => {
      const firstEpochBlockData = getBlockHeaderData(firstBlocksDataFilePath, 1);
      const lastEpochBlockData = getBlockHeaderData(firstBlocksDataFilePath, DIFFICULTY_ADJUSTMENT_INTERVAL);

      const actualPassedTime =
        BigInt(lastEpochBlockData.parsedBlockHeader.time) - BigInt(firstEpochBlockData.parsedBlockHeader.time);

      expect(await targetsHelperLib.countNewRoundedTarget(INITIAL_TARGET, actualPassedTime)).to.be.eq(INITIAL_TARGET);
    });

    it("should correctly count new targets for the newest epochs", async () => {
      let startEpochHeight = 800352;

      let firstEpochBlockData = getBlockHeaderData(newestBlocksDataFilePath, startEpochHeight);
      let lastEpochBlockData = getBlockHeaderData(
        newestBlocksDataFilePath,
        startEpochHeight + DIFFICULTY_ADJUSTMENT_INTERVAL - 1,
      );

      let currentTarget = bitsToTarget(lastEpochBlockData.parsedBlockHeader.bits);
      let actualPassedTime =
        BigInt(lastEpochBlockData.parsedBlockHeader.time) - BigInt(firstEpochBlockData.parsedBlockHeader.time);

      startEpochHeight += DIFFICULTY_ADJUSTMENT_INTERVAL;

      firstEpochBlockData = getBlockHeaderData(newestBlocksDataFilePath, startEpochHeight);
      lastEpochBlockData = getBlockHeaderData(
        newestBlocksDataFilePath,
        startEpochHeight + DIFFICULTY_ADJUSTMENT_INTERVAL - 1,
      );

      let newEpochTarget = bitsToTarget(lastEpochBlockData.parsedBlockHeader.bits);

      expect(await targetsHelperLib.countNewRoundedTarget(currentTarget, actualPassedTime)).to.be.eq(newEpochTarget);

      currentTarget = bitsToTarget(lastEpochBlockData.parsedBlockHeader.bits);
      actualPassedTime =
        BigInt(lastEpochBlockData.parsedBlockHeader.time) - BigInt(firstEpochBlockData.parsedBlockHeader.time);

      const nextEpochBlockData = getBlockHeaderData(
        newestBlocksDataFilePath,
        startEpochHeight + DIFFICULTY_ADJUSTMENT_INTERVAL + 1,
      );
      newEpochTarget = bitsToTarget(nextEpochBlockData.parsedBlockHeader.bits);

      expect(await targetsHelperLib.countNewRoundedTarget(currentTarget, actualPassedTime)).to.be.eq(newEpochTarget);
    });
  });

  describe("#countBlockWork", () => {
    it("should correctly count blockWork", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(newestBlocksDataFilePath, 800352, 815000);

        const blockTarget = bitsToTarget(blockData.parsedBlockHeader.bits);

        expect(await targetsHelperLib.countBlockWork(blockTarget)).to.be.eq(calculateWork(blockTarget));
      }
    });
  });

  describe("#bitsToTarget", () => {
    it("should correctly convert bits to target", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(newestBlocksDataFilePath, 800352, 815000);

        const blockTarget = bitsToTarget(blockData.parsedBlockHeader.bits);

        expect(await targetsHelperLib.bitsToTarget(blockData.parsedBlockHeader.bits)).to.be.eq(blockTarget);
      }
    });
  });

  describe("#targetToBits", () => {
    it("should correctly convert bits to target", async () => {
      for (let i = 0; i < 10; ++i) {
        const blockData = getRandomBlockHeaderData(newestBlocksDataFilePath, 800352, 815000);

        const blockTarget = bitsToTarget(blockData.parsedBlockHeader.bits);

        expect(await targetsHelperLib.targetToBits(blockTarget)).to.be.eq(blockData.parsedBlockHeader.bits);
      }
    });
  });
});
