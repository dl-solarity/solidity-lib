const { assert } = require("chai");

const ArrayConverterMock = artifacts.require("ArrayConverterMock");

describe("ArrayConverterMock", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await ArrayConverterMock.new();
  });

  describe("uint", () => {
    it("should convert static uint array to dynamic without errors", async () => {
      assert.equal(await mock.testUint(), true);
    });

    it("should convert static address array to dynamic without errors", async () => {
      assert.equal(await mock.testAddress(), true);
    });

    it("should convert static bool array to dynamic without errors", async () => {
      assert.equal(await mock.testBool(), true);
    });

    it("should convert static string array to dynamic without errors", async () => {
      assert.equal(await mock.testString(), true);
    });

    it("should convert static bytes32 array to dynamic without errors", async () => {
      assert.equal(await mock.testBytes32(), true);
    });
  });
});
