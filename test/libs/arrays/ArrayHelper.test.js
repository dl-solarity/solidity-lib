const { assert } = require("chai");
const { accounts } = require("../../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");
const { ZERO_BYTES32 } = require("../../../scripts/utils/constants");

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

    it("should reverse bytes32 array", async () => {
      const bytes32Array = [
        ZERO_BYTES32.replaceAll("0000", "1234"),
        ZERO_BYTES32.replaceAll("0000", "4321"),
        ZERO_BYTES32.replaceAll("0000", "abcd"),
      ];

      const arr = await mock.reverseBytes32(bytes32Array);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], bytes32Array[2]);
      assert.equal(arr[1], bytes32Array[1]);
      assert.equal(arr[2], bytes32Array[0]);
    });

    it("should reverse empty array", async () => {
      let arr = await mock.reverseUint([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseAddress([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseString([]);
      assert.equal(arr.length, 0);

      arr = await mock.reverseBytes32([]);
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

    it("should insert bytes32 array", async () => {
      const bytes32Array = [
        ZERO_BYTES32.replaceAll("0000", "1111"),
        ZERO_BYTES32.replaceAll("0000", "2222"),
        ZERO_BYTES32.replaceAll("0000", "3333"),
      ];

      const base = [bytes32Array[0], bytes32Array[1]];
      const index = 1;
      const what = [bytes32Array[2]];

      const res = await mock.insertBytes32(base, index, what);

      assert.equal(res[0].toFixed(), 2);
      assert.deepEqual(res[1], [bytes32Array[0], bytes32Array[2]]);
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

    describe("bounds", () => {
      const arbitraryArray = [10, 20, 30, 30, 30, 40, 50];
      const singletonArray = [100];
      const identicalElemsArray = [100, 100, 100, 100, 100];

      describe("lowerBound", () => {
        it("should find the correct indices in the arbitrary array", async () => {
          assert.equal((await mock.lowerBound(arbitraryArray, 1)).toNumber(), 0);
          assert.equal((await mock.lowerBound(arbitraryArray, 10)).toNumber(), 0);
          assert.equal((await mock.lowerBound(arbitraryArray, 15)).toNumber(), 1);
          assert.equal((await mock.lowerBound(arbitraryArray, 20)).toNumber(), 1);
          assert.equal((await mock.lowerBound(arbitraryArray, 25)).toNumber(), 2);
          assert.equal((await mock.lowerBound(arbitraryArray, 30)).toNumber(), 2);
          assert.equal((await mock.lowerBound(arbitraryArray, 35)).toNumber(), 5);
          assert.equal((await mock.lowerBound(arbitraryArray, 40)).toNumber(), 5);
          assert.equal((await mock.lowerBound(arbitraryArray, 45)).toNumber(), 6);
          assert.equal((await mock.lowerBound(arbitraryArray, 50)).toNumber(), 6);
          assert.equal((await mock.lowerBound(arbitraryArray, 100)).toNumber(), 7);
        });

        it("should find the correct indices in the singleton array", async () => {
          assert.equal((await mock.lowerBound(singletonArray, 1)).toNumber(), 0);
          assert.equal((await mock.lowerBound(singletonArray, 100)).toNumber(), 0);
          assert.equal((await mock.lowerBound(singletonArray, 150)).toNumber(), 1);
        });

        it("should find the correct indices in the identical elements array", async () => {
          assert.equal((await mock.lowerBound(identicalElemsArray, 1)).toNumber(), 0);
          assert.equal((await mock.lowerBound(identicalElemsArray, 100)).toNumber(), 0);
          assert.equal((await mock.lowerBound(identicalElemsArray, 150)).toNumber(), 5);
        });

        it("should find the correct indices in the empty array", async () => {
          assert.equal((await mock.lowerBound([], 100)).toNumber(), 0);
        });
      });

      describe("upperBound", () => {
        it("should find the correct indices in the arbitrary array", async () => {
          assert.equal((await mock.upperBound(arbitraryArray, 1)).toNumber(), 0);
          assert.equal((await mock.upperBound(arbitraryArray, 10)).toNumber(), 1);
          assert.equal((await mock.upperBound(arbitraryArray, 15)).toNumber(), 1);
          assert.equal((await mock.upperBound(arbitraryArray, 20)).toNumber(), 2);
          assert.equal((await mock.upperBound(arbitraryArray, 25)).toNumber(), 2);
          assert.equal((await mock.upperBound(arbitraryArray, 30)).toNumber(), 5);
          assert.equal((await mock.upperBound(arbitraryArray, 35)).toNumber(), 5);
          assert.equal((await mock.upperBound(arbitraryArray, 40)).toNumber(), 6);
          assert.equal((await mock.upperBound(arbitraryArray, 45)).toNumber(), 6);
          assert.equal((await mock.upperBound(arbitraryArray, 50)).toNumber(), 7);
          assert.equal((await mock.upperBound(arbitraryArray, 100)).toNumber(), 7);
        });

        it("should find the correct indices in the singleton array", async () => {
          assert.equal((await mock.upperBound(singletonArray, 1)).toNumber(), 0);
          assert.equal((await mock.upperBound(singletonArray, 100)).toNumber(), 1);
          assert.equal((await mock.upperBound(singletonArray, 150)).toNumber(), 1);
        });

        it("should find the correct indices in the identical elements array", async () => {
          assert.equal((await mock.upperBound(identicalElemsArray, 1)).toNumber(), 0);
          assert.equal((await mock.upperBound(identicalElemsArray, 100)).toNumber(), 5);
          assert.equal((await mock.upperBound(identicalElemsArray, 150)).toNumber(), 5);
        });

        it("should find the correct indices in the empty array", async () => {
          assert.equal((await mock.upperBound([], 100)).toNumber(), 0);
        });
      });
    });
  });
});
