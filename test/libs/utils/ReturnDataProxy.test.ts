import { expect } from "chai";
import hre from "hardhat";

import { AbiCoder } from "ethers";

import { wei } from "@scripts";

import { Reverter } from "@test-helpers";

import { RawReturnMock, ReturnDataProxyMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("ReturnDataProxy", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const coder: AbiCoder = ethers.AbiCoder.defaultAbiCoder();

  let rawMock: RawReturnMock;
  let proxyMock: ReturnDataProxyMock;

  before("setup", async () => {
    const RawReturnMock = await ethers.getContractFactory("RawReturnMock");
    const ReturnDataProxyMock = await ethers.getContractFactory("ReturnDataProxyMock");

    rawMock = await RawReturnMock.deploy();
    proxyMock = await ReturnDataProxyMock.deploy(await rawMock.getAddress());

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("call", () => {
    it("should set value properly", async () => {
      await proxyMock.callSetMirror(wei("1"));

      expect(await rawMock.getMirror()).to.equal(wei("1"));
    });

    it("should transfer value properly", async () => {
      await proxyMock.callWithValue({ value: wei("1") });

      expect(await rawMock.getBalance()).to.equal(wei("1"));
    });

    it("should revert with message", async () => {
      await expect(proxyMock.callRevertWithMessage()).to.be.revertedWithCustomError(rawMock, "Test").withArgs();
    });
  });

  describe("staticcall", () => {
    it("should return value properly", async () => {
      const proxyValue = await proxyMock.staticCallGetEntry();
      const rawValue = await rawMock.getEntry();

      expect(proxyValue).to.deep.equal(rawValue);
    });

    it("should return revert message", async () => {
      await expect(proxyMock.staticCallRevertWithMessage()).to.be.revertedWithCustomError(rawMock, "Test").withArgs();
    });

    it("should return value with passed arguments", async () => {
      const args = coder.encode(["uint256", "string"], ["123", "test"]);

      const proxyValue = await proxyMock.staticCallWithArgs(args, "test", 123);
      const rawValue = await rawMock.getEntryWithArgs(args, "test", 123);

      expect(proxyValue).to.deep.equal(rawValue);
    });
  });

  describe("delegatecall", () => {
    it("should set value properly", async () => {
      await proxyMock.delegateCallSetMirror(wei("1"));

      expect(await proxyMock.getBack()).to.equal(wei("1"));
      expect(await rawMock.getMirror()).to.equal(0n);
    });

    it("should revert with message", async () => {
      await expect(proxyMock.delegateCallRevertWithMessage()).to.be.revertedWithCustomError(rawMock, "Test").withArgs();
    });
  });
});
