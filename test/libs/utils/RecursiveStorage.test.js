const { assert } = require("chai");
const { web3 } = require("hardhat");
const truffleAssert = require("truffle-assertions");

const RecursiveStorageMock = artifacts.require("RecursiveStorageMock");

RecursiveStorageMock.numberFormat = "BigNumber";

describe("RecursiveStorage", () => {
  let mock;

  const key = "SHORT_KEY";
  const compositeKey = ["VERY", "LONG", "COMPOSITE", "KEY"];
  const bytesMockValues = ["0xdead", "0xc0ffee"];

  beforeEach("setup", async () => {
    mock = await RecursiveStorageMock.new();
  });

  describe("set", () => {
    it("should not set if value is empty", async () => {
      await truffleAssert.reverts(mock.setBytes(key, "0x"), "RecursiveStorage: empty value");
      await truffleAssert.reverts(mock.setCompositeKeyBytes(compositeKey, "0x"), "RecursiveStorage: empty value");
    });

    it("should set value properly if all conditions are met", async () => {
      await mock.setUint256(key, 123);
      await mock.setCompositeKeyUint256(compositeKey, 321);

      assert.equal((await mock.getUint256(key)).toNumber(), 123);
      assert.equal((await mock.getCompositeKeyUint256(compositeKey)).toNumber(), 321);

      assert.equal(await mock.getBytes(key), web3.eth.abi.encodeParameter("uint256", 123));
      assert.equal(await mock.getCompositeKeyBytes(compositeKey), web3.eth.abi.encodeParameter("uint256", 321));

      await mock.setBytes(key, bytesMockValues[0]);
      await mock.setCompositeKeyBytes(compositeKey, bytesMockValues[1]);

      assert.equal(await mock.getBytes(key), bytesMockValues[0]);
      assert.equal(await mock.getCompositeKeyBytes(compositeKey), bytesMockValues[1]);
    });
  });

  describe("remove", () => {
    it("should not remove if value does not exist", async () => {
      await truffleAssert.reverts(mock.remove(key), "RecursiveStorage: value does not exist");
      await truffleAssert.reverts(mock.removeCompositeKey(compositeKey), "RecursiveStorage: value does not exist");
    });

    it("should remove properly if all conditions are met", async () => {
      await mock.setBytes(key, bytesMockValues[0]);
      await mock.setCompositeKeyBytes(compositeKey, bytesMockValues[1]);

      assert.isTrue(await mock.exists(key));
      assert.isTrue(await mock.existsCompositeKey(compositeKey));

      await mock.remove(key);
      await mock.removeCompositeKey(compositeKey);

      assert.isFalse(await mock.exists(key));
      assert.isFalse(await mock.existsCompositeKey(compositeKey));
    });
  });
});
