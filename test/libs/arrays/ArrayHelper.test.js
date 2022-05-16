const { assert } = require("chai");

const ArrayHelperMock = artifacts.require("ArrayHelperMock");

describe("ArrayHelperMock", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await ArrayHelperMock.new();
  });

  describe("reverse", async () => {
    it("should reverse array", async () => {
      const arr = await mock.reverse([1, 2, 3]);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 3);
      assert.equal(arr[1], 2);
      assert.equal(arr[2], 1);
    });

    it("should reverse empty array", async () => {
      const arr = await mock.reverse([]);

      assert.equal(arr.length, 0);
    });
  });
});
