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

  describe("array cast", () => {
    const addressArrays = [[], [ZERO_ADDR, ETHER_ADDR]];
    const bytes32Arrays = [[], addressArrays[1].map((e) => web3.eth.abi.encodeParameter("address", e))];
    const uint256Arrays = [[], bytes32Arrays[1].map((e) => web3.eth.abi.decodeParameter("uint256", e))];

    describe("asUint256Array", () => {
      it("should convert bytes32 array to uint256 array properly", async () => {
        for (const [idx, bytes32Array] of bytes32Arrays.entries()) {
          assert.deepEqual(
            (await mock.asUint256ArrayFromBytes32Array(bytes32Array)).map((e) => e.toFixed()),
            uint256Arrays[idx]
          );
        }
      });

      it("should convert address array to uint256 array properly", async () => {
        for (const [idx, addressArray] of addressArrays.entries()) {
          assert.deepEqual(
            (await mock.asUint256ArrayFromAddressArray(addressArray)).map((e) => e.toFixed()),
            uint256Arrays[idx]
          );
        }
      });
    });

    describe("asAddressArray", () => {
      it("should convert bytes32 array to address array properly", async () => {
        for (const [idx, bytes32Array] of bytes32Arrays.entries()) {
          assert.deepEqual(await mock.asAddressArrayFromBytes32Array(bytes32Array), addressArrays[idx]);
        }
      });

      it("should convert uint256 array to address array properly", async () => {
        for (const [idx, uint256Array] of uint256Arrays.entries()) {
          assert.deepEqual(await mock.asAddressArrayFromUint256Array(uint256Array), addressArrays[idx]);
        }
      });
    });

    describe("asBytes32Array", () => {
      it("should convert uint256 array to bytes32 array properly", async () => {
        for (const [idx, uint256Array] of uint256Arrays.entries()) {
          assert.deepEqual(await mock.asBytes32ArrayFromUint256Array(uint256Array), bytes32Arrays[idx]);
        }
      });

      it("should convert address array to bytes32 array properly", async () => {
        for (const [idx, addressArray] of addressArrays.entries()) {
          assert.deepEqual(await mock.asBytes32ArrayFromAddressArray(addressArray), bytes32Arrays[idx]);
        }
      });
    });
  });

  describe("singleton array", () => {
    const MOCKED_BYTES32 = ZERO_BYTES32.replaceAll("0000", "1234");

    it("should build singleton arrays properly", async () => {
      assert.deepEqual(
        (await mock.asSingletonArrayFromUint256(123)).map((e) => e.toNumber()),
        [123]
      );

      assert.deepEqual(await mock.asSingletonArrayFromAddress(ETHER_ADDR), [ETHER_ADDR]);
      assert.deepEqual(await mock.asSingletonArrayFromBool(false), [false]);
      assert.deepEqual(await mock.asSingletonArrayFromString("1"), ["1"]);
      assert.deepEqual(await mock.asSingletonArrayFromBytes32(MOCKED_BYTES32), [MOCKED_BYTES32]);
    });
  });

  describe("static2dynamic", () => {
    it("should convert static uint array to dynamic", async () => {
      assert.equal(await mock.testUint(), true);
    });

    it("should convert static address array to dynamic", async () => {
      assert.equal(await mock.testAddress(), true);
    });

    it("should convert static bool array to dynamic", async () => {
      assert.equal(await mock.testBool(), true);
    });

    it("should convert static string array to dynamic", async () => {
      assert.equal(await mock.testString(), true);
    });

    it("should convert static bytes32 array to dynamic", async () => {
      assert.equal(await mock.testBytes32(), true);
    });
  });
});
