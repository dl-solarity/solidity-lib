const { assert } = require("chai");
const { accounts } = require("../../../scripts/helpers/utils");

const ArrayHelperMock = artifacts.require("ArrayHelperMock");

ArrayHelperMock.numberFormat = "BigNumber";

describe("ArrayHelperMock", () => {
  let mock;

  let FIRST;
  let SECOND;
  let THIRD;

  before("setup", async () => {
    FIRST = await accounts(0);
    SECOND = await accounts(1);
    THIRD = await accounts(2);
  });

  beforeEach("setup", async () => {
    mock = await ArrayHelperMock.new();
  });

  describe("reverse", async () => {
    it("should reverse uint array", async () => {
      const arr = await mock.reverseUint([1, 2, 3]);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 3);
      assert.equal(arr[1], 2);
      assert.equal(arr[2], 1);
    });

    it("should reverse address array", async () => {
      const arr = await mock.reverseAddress([FIRST, SECOND, THIRD]);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], THIRD);
      assert.equal(arr[1], SECOND);
      assert.equal(arr[2], FIRST);
    });

    it("should reverse empty array", async () => {
      let arr = await mock.reverseUint([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseAddress([]);
      assert.equal(arr.length, 0);
    });
  });

  describe("asArray", () => {
    it("should build arrays", async () => {
      assert.deepEqual(
        (await mock.asArrayUint("123")).map((e) => e.toFixed()),
        ["123"]
      );
      assert.deepEqual(await mock.asArrayAddress(FIRST), [FIRST]);
    });
  });
});
