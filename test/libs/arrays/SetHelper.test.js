const { assert } = require("chai");
const { accounts } = require("../../../scripts/helpers/utils");

const SetHelperMock = artifacts.require("SetHelperMock");

SetHelperMock.numberFormat = "BigNumber";

describe("SetHelperMock", () => {
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
    mock = await SetHelperMock.new();
  });

  describe("add", () => {
    it("should add to address set", async () => {
      await mock.addToAddressSet([FIRST, SECOND]);

      assert.deepEqual(await mock.getAddressSet(), [FIRST, SECOND]);
    });

    it("should add to uint set", async () => {
      await mock.addToUintSet([1]);

      assert.deepEqual(
        (await mock.getUintSet()).map((e) => e.toFixed()),
        ["1"]
      );
    });

    it("should add to string set", async () => {
      await mock.addToStringSet(["1", "2", "3"]);

      assert.deepEqual(await mock.getStringSet(), ["1", "2", "3"]);
    });
  });

  describe("remove", () => {
    it("should remove from address set", async () => {
      await mock.addToAddressSet([FIRST, SECOND]);
      await mock.removeFromAddressSet([SECOND, THIRD]);

      assert.deepEqual(await mock.getAddressSet(), [FIRST]);
    });

    it("should remove from uint set", async () => {
      await mock.addToUintSet([1]);
      await mock.removeFromUintSet([1]);

      assert.deepEqual(await mock.getUintSet(), []);
    });

    it("should remove from string set", async () => {
      await mock.addToStringSet(["1", "2", "3"]);
      await mock.removeFromStringSet(["1", "4"]);

      assert.deepEqual(await mock.getStringSet(), ["3", "2"]);
    });
  });
});
