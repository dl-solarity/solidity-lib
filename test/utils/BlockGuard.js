const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");
const { getCurrentBlock } = require("../helpers/block-helper");

const BlockGuardMock = artifacts.require("BlockGuardMock");

BlockGuardMock.numberFormat = "BigNumber";

describe("BlockGuard", () => {
  let mock;

  let FIRST;

  before("setup", async () => {
    FIRST = await accounts(0);
  });

  beforeEach("setup", async () => {
    mock = await BlockGuardMock.new();
  });

  describe("lockBlock", () => {
    it("should return zero if the resource key hasn't been locked", async () => {
      assert.equal((await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).toFixed(), "0");
    });

    it("should have current lock block if has been locked", async () => {
      await mock.deposit();

      assert.equal(
        (await mock.getLatestLockBlock(await mock.DEPOSIT_WITHDRAW_RESOURCE(), FIRST)).toNumber(),
        await getCurrentBlock()
      );
    });
  });

  describe("checkBlock", () => {
    it("should allow to call in different blocks", async () => {
      await mock.deposit();

      await truffleAssert.passes(mock.withdraw());
    });

    it("should disallow to call in the same block", async () => {
      await truffleAssert.reverts(
        mock.multicall([mock.contract.methods.deposit().encodeABI(), mock.contract.methods.withdraw().encodeABI()]),
        "BlockGuard: locked"
      );
    });
  });

  describe("checkLockBlock", () => {
    it("should allow to call in different blocks", async () => {
      await mock.lock();

      assert.equal(
        (await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).toNumber(),
        await getCurrentBlock()
      );

      await mock.lock();

      assert.equal(
        (await mock.getLatestLockBlock(await mock.LOCK_LOCK_RESOURCE(), FIRST)).toNumber(),
        await getCurrentBlock()
      );
    });

    it("should disallow to call in the same block", async () => {
      await truffleAssert.reverts(
        mock.multicall([mock.contract.methods.lock().encodeABI(), mock.contract.methods.lock().encodeABI()]),
        "BlockGuard: locked"
      );
    });
  });
});
