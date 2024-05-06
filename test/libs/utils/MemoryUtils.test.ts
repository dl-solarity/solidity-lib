import { expect } from "chai";
import { ethers } from "hardhat";

import { Reverter } from "@/test/helpers/reverter";

import { MemoryUtilsMock } from "@ethers-v6";

describe.only("MemoryUtils", () => {
  const reverter = new Reverter();

  let mock: MemoryUtilsMock;

  before("setup", async () => {
    const MemoryUtilsMock = await ethers.getContractFactory("MemoryUtilsMock");
    mock = await MemoryUtilsMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe.only("copyMemory", () => {
    it("should copy small chunks of memory", async () => {
      await mock.testSmallMemoryCopy();

      await expect(mock.testSmallMemoryCopy()).to.be.eventually.fulfilled;
    });

    it("should copy big chunks of memory", async () => {
      await expect(mock.testBigMemoryCopy()).to.be.eventually.fulfilled;
    });
  });
});
