const { assert } = require("chai");
const { accounts } = require("../../../scripts/helpers/utils");
const truffleAssert = require("truffle-assertions");

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

    it("should reverse string array", async () => {
      const arr = await mock.reverseString(["1", "2", "3"]);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "3");
      assert.equal(arr[1], "2");
      assert.equal(arr[2], "1");
    });

    it("should reverse empty array", async () => {
      let arr = await mock.reverseUint([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseAddress([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseString([]);
      assert.equal(arr.length, 0);
    });
  });

  describe("insert", () => {
    it("should insert uint array", async () => {
      const base = [1, 2, 3, 0, 0, 0];
      const index = 3;
      const what = [4, 5, 6];

      const res = await mock.insertUint(base, index, what);

      assert.equal(res[0].toFixed(), 6);
      assert.deepEqual(
        res[1].map((e) => e.toFixed()),
        ["1", "2", "3", "4", "5", "6"]
      );
    });

    it("should insert address array", async () => {
      const base = [FIRST, SECOND];
      const index = 1;
      const what = [THIRD];

      const res = await mock.insertAddress(base, index, what);

      assert.equal(res[0].toFixed(), 2);
      assert.deepEqual(res[1], [FIRST, THIRD]);
    });

    it("should insert string array", async () => {
      const base = ["1", "2"];
      const index = 1;
      const what = ["3"];

      const res = await mock.insertString(base, index, what);

      assert.equal(res[0].toFixed(), 2);
      assert.deepEqual(res[1], ["1", "3"]);
    });

    it("should revert in case of out of bound insertion", async () => {
      await truffleAssert.reverts(mock.insertUint([1], 1, [2]));
      await truffleAssert.reverts(mock.insertAddress([], 0, [FIRST]));
      await truffleAssert.reverts(mock.insertString(["1", "2"], 2, ["1"]));
    });
  });

  describe("asArray", () => {
    it("should build arrays", async () => {
      assert.deepEqual(
        (await mock.asArrayUint("123")).map((e) => e.toFixed()),
        ["123"]
      );
      assert.deepEqual(await mock.asArrayAddress(FIRST), [FIRST]);
      assert.deepEqual(await mock.asArrayString("1"), ["1"]);
    });
  });
});
