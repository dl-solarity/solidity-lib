import { expect } from "chai";
import { ethers } from "hardhat";

import { Reverter } from "@/test/helpers/reverter";

import { MemoryUtilsMock } from "@ethers-v6";

describe("MemoryUtils", () => {
  const reverter = new Reverter();

  let mock: MemoryUtilsMock;

  before("setup", async () => {
    const MemoryUtilsMock = await ethers.getContractFactory("MemoryUtilsMock");
    mock = await MemoryUtilsMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("copyMemory", () => {
    it("should copy arbitrary chunks of memory (bytes)", async () => {
      await expect(mock.testBytesMemoryCopy(ethers.randomBytes(20))).to.be.eventually.fulfilled;
    });

    it("should copy arbitrary chunks of memory (bytes32[])", async () => {
      await expect(mock.testBytes32MemoryCopy([ethers.randomBytes(32), ethers.randomBytes(32)])).to.be.eventually
        .fulfilled;
    });

    it("should copy 20 bytes of memory", async () => {
      await expect(mock.testUnsafeMemoryCopy(ethers.randomBytes(20))).to.be.eventually.fulfilled;
    });

    it("should copy 32 bytes of memory", async () => {
      await expect(mock.testUnsafeMemoryCopy(ethers.randomBytes(32))).to.be.eventually.fulfilled;
    });

    it("should copy 1000 bytes of memory", async () => {
      await expect(mock.testUnsafeMemoryCopy(ethers.randomBytes(1000))).to.be.eventually.fulfilled;
    });

    it("should copy 4096 bytes of memory", async () => {
      await expect(mock.testUnsafeMemoryCopy(ethers.randomBytes(4096))).to.be.eventually.fulfilled;
    });

    it("should copy partial chunks of memory", async () => {
      await expect(mock.testPartialCopy(ethers.randomBytes(15))).to.be.eventually.fulfilled;
    });

    it("should cover getter functions", async () => {
      await expect(mock.testForCoverage()).to.be.eventually.fulfilled;
    });
  });
});
