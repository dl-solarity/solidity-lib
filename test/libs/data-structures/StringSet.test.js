const { assert } = require("chai");
const { accounts } = require("../../../scripts/helpers/utils");

const StringSetMock = artifacts.require("StringSetMock");

StringSetMock.numberFormat = "BigNumber";

describe("StringSetMock", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await StringSetMock.new();
  });

  describe("add()", () => {
    it("should add different strings twice", async () => {
      let expected1 = "test1";
      let expected2 = "test2";

      await mock.add(expected1);
      await mock.add(expected2);

      let set = await mock.getSet();

      assert.equal(set.length, 2);
      assert.equal(set[0], expected1);
      assert.equal(set[1], expected2);
    });

    it("should add empty string", async () => {
      let expected = "";

      await mock.add(expected);

      let set = await mock.getSet();

      assert.equal(set.length, 1);
      assert.equal(set[0], expected);
    });

    it("should add same string twice", async () => {
      let expected = "test";

      await mock.add(expected);
      await mock.add(expected);

      let set = await mock.getSet();

      assert.equal(set.length, 1);
      assert.equal(set[0], expected);
    });
  });

  describe("remove()", async () => {
    it("should remove string", async () => {
      let expected = "test";

      await mock.add(expected);

      await mock.remove(expected);

      let set = await mock.getSet();
      assert.equal(set.length, 0);
    });

    it("should call remove at empty set", async () => {
      await mock.remove("test");
    });

    it("should remove non-existent string", async () => {
      let expected = "test";

      await mock.add(expected);

      await mock.remove(expected + "1");

      let set = await mock.getSet();
      assert.equal(set.length, 1);
      assert.equal(set[0], expected);
    });

    it("should remove from middle", async () => {
      let expected1 = "test1";
      let expected2 = "test2";
      let expected3 = "test3";

      await mock.add(expected1);
      await mock.add(expected2);
      await mock.add(expected3);

      await mock.remove(expected2);

      let set = await mock.getSet();
      assert.equal(set.length, 2);
      assert.equal(set[0], expected1);
      assert.equal(set[1], expected3);
    });
  });

  describe("contains()", () => {
    it("should return true", async () => {
      let expected = "test";

      await mock.add(expected);

      assert.isTrue(await mock.contains(expected));
    });

    it("should return false", async () => {
      let expected = "test";

      await mock.add(expected);

      assert.isFalse(await mock.contains(expected + "1"));
    });
  });

  describe("length()", async () => {
    it("should return correct length", async () => {
      let expected = "test";

      assert.equal(await mock.length(), 0);

      await mock.add(expected);
      assert.equal(await mock.length(), 1);

      await mock.add(expected);
      assert.equal(await mock.length(), 1);
    });
  });

  describe("at()", async () => {
    it("should correctly return 10 values", async () => {
      let expected = "test";

      for (let i = 0; i < 10; i++) {
        await mock.add(expected + i);
      }

      for (let i = 0; i < 10; i++) {
        assert.equal(await mock.at(i), expected + i);
      }
    });
  });
});
