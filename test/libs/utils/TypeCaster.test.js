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
          const bytes = await mock.asBytes_Bool(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("bool", value));
          assert.equal(await mock.asBool_Bytes(bytes), value);
        }
      });
    });

    describe("address", () => {
      const values = [ZERO_ADDR, ETHER_ADDR];

      it("should convert address to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.asBytes_Address(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("address", value));
          assert.equal(await mock.asAddress_Bytes(bytes), value);
        }
      });
    });

    describe("bytes32", () => {
      const values = [ZERO_BYTES32, ZERO_BYTES32.replaceAll("00", "12")];

      it("should convert bytes32 to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.asBytes_Bytes32(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("bytes32", value));
          assert.equal(await mock.asBytes32_Bytes(bytes), value);
        }
      });
    });

    describe("uint256", () => {
      const values = [0, 1337];

      it("should convert uint256 to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.asBytes_Uint256(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("uint256", value));
          assert.equal((await mock.asUint256_Bytes(bytes)).toNumber(), value);
        }
      });
    });

    describe("string", () => {
      const values = ["", "mock", "mock_mock_mock_mock_mock_mock_mock_mock_mock_mock_mock_mock"];

      it("should convert string to bytes and vice versa properly", async () => {
        for (const value of values) {
          const bytes = await mock.asBytes_String(value);

          assert.equal(bytes, web3.eth.abi.encodeParameter("string", value));
          assert.equal(await mock.asString_Bytes(bytes), value);
        }
      });
    });
  });

  describe("bytes32 array", () => {
    const values = [[], [ZERO_BYTES32.replaceAll("00", "12"), ZERO_BYTES32.replaceAll("00", "34")]];

    it("should convert bytes32 array to bytes and vice versa properly", async () => {
      for (const value of values) {
        const bytes = await mock.asBytes_Bytes32Array(value);

        assert.equal(bytes, web3.eth.abi.encodeParameter("bytes32[]", value));
        assert.deepEqual(await mock.asBytes32Array_Bytes(bytes), value);
      }
    });
  });

  describe("uint256 array", () => {
    const values = [[], [1337, 0, 123]];

    it("should convert uint256 array to bytes32 array and vice versa properly", async () => {
      for (const value of values) {
        const bytes32Array = await mock.asBytes32Array_Uint256Array(value);

        assert.deepEqual(
          bytes32Array,
          value.map((e) => web3.eth.abi.encodeParameter("uint256", e))
        );
        assert.deepEqual(
          (await mock.asUint256Array_Bytes32Array(bytes32Array)).map((e) => e.toNumber()),
          value
        );
      }
    });
  });

  describe("address array", () => {
    const values = [[], [ZERO_ADDR, ETHER_ADDR]];

    it("should convert address array to bytes32 array and vice versa properly", async () => {
      for (const value of values) {
        const bytes32Array = await mock.asBytes32Array_AddressArray(value);

        assert.deepEqual(
          bytes32Array,
          value.map((e) => web3.eth.abi.encodeParameter("address", e))
        );
        assert.deepEqual(await mock.asAddressArray_Bytes32Array(bytes32Array), value);
      }
    });
  });

  describe("singleton array", () => {
    it("should build singleton arrays properly", async () => {
      assert.deepEqual(
        (await mock.asSingletonArray_Uint256(123)).map((e) => e.toNumber()),
        [123]
      );
      assert.deepEqual(await mock.asSingletonArray_Address(ETHER_ADDR), [ETHER_ADDR]);
      assert.deepEqual(await mock.asSingletonArray_String("1"), ["1"]);
    });
  });
});
