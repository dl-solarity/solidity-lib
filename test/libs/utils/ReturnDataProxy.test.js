const truffleAssert = require("truffle-assertions");

const { assert } = require("chai");
const { web3 } = require("hardhat");

const RawReturnMock = artifacts.require("RawReturnMock");
const ReturnDataProxyMock = artifacts.require("ReturnDataProxyMock");

ReturnDataProxyMock.numberFormat = "BigNumber";

describe("ReturnDataProxy", () => {
  let rawMock;
  let proxyMock;

  beforeEach("setup", async () => {
    rawMock = await RawReturnMock.new();
    proxyMock = await ReturnDataProxyMock.new(rawMock.address);
  });

  describe("call", () => {
    it("should set value properly", async () => {
      const value = web3.utils.toWei("1", "ether");

      await proxyMock.callSetMirror(value);

      assert.equal(await rawMock.getMirror(), value);
    });

    it("should revert with message", async () => {
      await truffleAssert.reverts(proxyMock.callRevertWithMessage(), "test");
    });
  });

  describe("staticcall", () => {
    it("should return value properly", async () => {
      const proxyValue = await proxyMock.staticCallGetEntry();
      const rawValue = await rawMock.getEntry();

      assert.deepEqual(proxyValue, rawValue);
    });

    it("should return revert message", async () => {
      await truffleAssert.reverts(proxyMock.staticCallRevertWithMessage(), "test");
    });

    it("should return value with passed arguments", async () => {
      const args = web3.eth.abi.encodeParameters(["uint256", "string"], ["123", "test"]);
      const proxyValue = await proxyMock.staticCallWithArgs(args, "test", 123);
      const rawValue = await rawMock.getEntryWithArgs(args, "test", 123);

      assert.deepEqual(proxyValue, rawValue);
    });
  });

  describe("delegatecall", () => {
    it("should set value properly", async () => {
      const value = web3.utils.toWei("1", "ether");

      await proxyMock.delegateCallSetMirror(value);

      assert.equal(await proxyMock.getBack(), value);
      assert.equal(await rawMock.getMirror(), "0");
    });

    it("should revert with message", async () => {
      await truffleAssert.reverts(proxyMock.delegateCallRevertWithMessage(), "test");
    });
  });
});
