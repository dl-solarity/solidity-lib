const { assert } = require("chai");
const { accounts } = require("../../../scripts/utils/utils");
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

  describe("prefix sum array", () => {
    function getArraySum(arr) {
      return arr.reduce((prev, cur) => prev + cur, 0);
    }

    function countPrefixes(arr) {
      return arr.map((e, idx) => getArraySum(arr.slice(0, idx + 1)));
    }

    const array = [0, 100, 50, 4, 34, 520, 4];

    describe("countPrefixes", () => {
      it("should compute prefix array properly", async () => {
        assert.deepEqual(await mock.countPrefixes([]), []);
        assert.deepEqual(
          (await mock.countPrefixes(array)).map((e) => e.toNumber()),
          countPrefixes(array)
        );
      });
    });

    describe("getRangeSum", () => {
      it("should get the range sum properly if all conditions are met", async () => {
        for (let l = 0; l < array.length; l++) {
          for (let r = l; r < array.length; r++) {
            assert.equal((await mock.getRangeSum(array, l, r)).toNumber(), getArraySum(array.slice(l, r + 1)));
          }
        }
      });

      it("should revert if the first index is greater than the last one", async () => {
        await truffleAssert.reverts(mock.getRangeSum(array, array.length - 1, 0), "ArrayHelper: wrong range");
        await truffleAssert.reverts(mock.getRangeSum(array, 1, 0), "ArrayHelper: wrong range");
        await truffleAssert.reverts(mock.getRangeSum(array, 2, 1), "ArrayHelper: wrong range");
      });

      it("should revert if one of the indexes is out of range", async () => {
        await truffleAssert.reverts(mock.getRangeSum([], 0, 0));
        await truffleAssert.reverts(mock.getRangeSum(array, 0, array.length));
      });
    });
  });
});
