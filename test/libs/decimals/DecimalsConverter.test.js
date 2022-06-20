const { assert } = require("chai");
const { toBN, wei } = require("../../../scripts/helpers/utils");

const DecimalsConverterMock = artifacts.require("DecimalsConverterMock");

DecimalsConverterMock.numberFormat = "BigNumber";

describe("DecimalsConverter", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await DecimalsConverterMock.new();
  });

  describe("convert", () => {
    it("should convert", async () => {
      assert.equal((await mock.convert(wei("1"), 18, 6)).toFixed(), wei("1", 6));
      assert.equal((await mock.convert(wei("1", 6), 6, 18)).toFixed(), wei("1"));
      assert.equal((await mock.convert(wei("1", 6), 18, 18)).toFixed(), wei("1", 6));
    });
  });

  describe("to18", () => {
    it("should convert to 18", async () => {
      assert.equal((await mock.to18(wei("1", 6), 6)).toFixed(), wei("1"));
      assert.equal((await mock.to18(wei("1", 8), 8)).toFixed(), wei("1"));
      assert.equal((await mock.to18(wei("1", 6), 8)).toFixed(), wei("1", 16));
      assert.equal((await mock.to18(wei("1", 30), 30)).toFixed(), wei("1"));
    });
  });

  describe("from18", () => {
    it("should convert from 18", async () => {
      assert.equal((await mock.from18(wei("1"), 6)).toFixed(), wei("1", 6));
      assert.equal((await mock.from18(wei("1"), 8)).toFixed(), wei("1", 8));
      assert.equal((await mock.from18(wei("1", 16), 8)).toFixed(), wei("1", 6));
      assert.equal((await mock.from18(wei("1", 5), 8)).toFixed(), "0");
      assert.equal((await mock.from18(wei("1"), 30)).toFixed(), wei("1", 30));
    });
  });

  describe("round18", () => {
    it("should round 18", async () => {
      assert.equal((await mock.round18(wei("1"), 18)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1"), 6)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1"), 30)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1", 7), 7)).toFixed(), "0");

      const badNum1 = toBN(wei("1")).plus("123").toFixed();
      const badNum2 = toBN(wei("1")).plus(wei("1", 7)).plus("123").toFixed();

      assert.equal((await mock.round18(badNum1, 4)).toFixed(), wei("1"));
      assert.equal((await mock.round18(badNum2, 12)).toFixed(), toBN(wei("1")).plus(wei("1", 7)).toFixed());
    });
  });
});
