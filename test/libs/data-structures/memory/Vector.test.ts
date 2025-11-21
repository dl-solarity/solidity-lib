import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import type { VectorMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("Vector", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let vector: VectorMock;

  before("setup", async () => {
    const VectorMock = await ethers.getContractFactory("VectorMock");
    vector = await VectorMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("raw vector", () => {
    it("should test new", async () => {
      await vector.testNew();
    });

    it("should test array push", async () => {
      await vector.testArrayPush();
    });

    it("should test push and pop", async () => {
      await vector.testPushAndPop();
    });

    it("should test resize", async () => {
      await vector.testResize();
    });

    it("should test resize and set", async () => {
      await vector.testResizeAndSet();
    });

    it("should test empty vector", async () => {
      await expect(vector.testEmptyPop()).to.be.revertedWithCustomError(vector, "PopEmptyVector").withArgs();
      await expect(vector.testEmptySet()).to.be.revertedWithCustomError(vector, "IndexOutOfBounds").withArgs(1, 0);
      await expect(vector.testEmptyAt()).to.be.revertedWithCustomError(vector, "IndexOutOfBounds").withArgs(0, 0);
    });
  });

  describe("uint vector", () => {
    it("should test uint vector", async () => {
      await vector.testUintFunctionality();
    });
  });

  describe("bytes32 vector", () => {
    it("should test bytes32 vector", async () => {
      await vector.testBytes32Functionality();
    });
  });

  describe("address vector", () => {
    it("should test address vector", async () => {
      await vector.testAddressFunctionality();
    });
  });
});
