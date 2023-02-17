const { assert } = require("chai");
const { web3 } = require("hardhat");
const { ZERO_ADDR, ETHER_ADDR, ZERO_BYTES32 } = require("../../../scripts/utils/constants");

const TypeCasterMock = artifacts.require("TypeCasterMock");

TypeCasterMock.numberFormat = "BigNumber";

describe("TypeCaster", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await TypeCasterMock.new();
  });

  describe("bytes", () => {
    describe("bool", () => {
      const values = [true, false];

      it("should convert bool to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.boolToBytes(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("bool", value));
          assert.equal(await mock.asBool(bytes), value);
        }
      });
    });

    describe("address", () => {
      const values = [ZERO_ADDR, ETHER_ADDR];

      it("should convert address to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.addressToBytes(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("address", value));
          assert.equal(await mock.asAddress(bytes), value);
        }
      });
    });

    describe("bytes32", () => {
      const values = [ZERO_BYTES32, ZERO_BYTES32.replaceAll("00", "12")];

      it("should convert bytes32 to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.bytes32ToBytes(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("bytes32", value));
          assert.equal(await mock.asBytes32(bytes), value);
        }
      });
    });

    describe("uint256", () => {
      const values = [0, 1337];

      it("should convert uint256 to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.uint256ToBytes(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("uint256", value));
          assert.equal((await mock.asUint256(bytes)).toNumber(), value);
        }
      });
    });

    describe("string", () => {
      const values = ["", "mock", "mock_mock_mock_mock_mock_mock_mock_mock_mock_mock_mock_mock"];

      it("should convert string to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.stringToBytes(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("string", value));
          assert.equal(await mock.asString(bytes), value);
        }
      });
    });
  });

  describe("array", () => {
    describe("asArray", () => {
      it("should build arrays properly", async () => {
        assert.deepEqual(
          (await mock.asArrayUint256(123)).map((e) => e.toNumber()),
          [123]
        );
        assert.deepEqual(await mock.asArrayAddress(ETHER_ADDR), [ETHER_ADDR]);
        assert.deepEqual(await mock.asArrayString("1"), ["1"]);
      });
    });
  });
});
