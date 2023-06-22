const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../scripts/utils/constants");

const truffleAssert = require("truffle-assertions");

const MultiOwnable = artifacts.require("MultiOwnableMock");

describe("MultiOwnable", () => {
  let FIRST;
  let SECOND;
  let THIRD;

  let multiOwnable;

  before("setup", async () => {
    FIRST = await accounts(0);
    SECOND = await accounts(1);
    THIRD = await accounts(2);
  });

  beforeEach("setup", async () => {
    multiOwnable = await MultiOwnable.new();

    await multiOwnable.__MultiOwnableMock_init();
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(multiOwnable.mockInit(), "Initializable: contract is not initializing");
      await truffleAssert.reverts(
        multiOwnable.__MultiOwnableMock_init(),
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await truffleAssert.reverts(
        multiOwnable.addOwners([THIRD], { from: SECOND }),
        "MultiOwnable: caller is not the owner"
      );

      await multiOwnable.addOwners([THIRD]);
      await truffleAssert.reverts(
        multiOwnable.removeOwners([THIRD], { from: SECOND }),
        "MultiOwnable: caller is not the owner"
      );

      await truffleAssert.reverts(
        multiOwnable.renounceOwnership({ from: SECOND }),
        "MultiOwnable: caller is not the owner"
      );
    });
  });

  describe("addOwners()", () => {
    it("should correctly add owners", async () => {
      await multiOwnable.addOwners([SECOND, THIRD]);

      assert.equal(await multiOwnable.isOwner(SECOND), true);
      assert.equal(await multiOwnable.isOwner(THIRD), true);
    });

    it("should not add null address", async () => {
      await truffleAssert.reverts(multiOwnable.addOwners([ZERO_ADDR]), "MultiOwnable: zero address can not be added");
    });
  });

  describe("removeOwners()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([SECOND]);
      await multiOwnable.removeOwners([SECOND, THIRD]);

      assert.equal(await multiOwnable.isOwner(SECOND), false);
      assert.equal(await multiOwnable.isOwner(FIRST), true);
    });
  });

  describe("renounceOwnership()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([THIRD]);
      assert.equal(await multiOwnable.isOwner(THIRD), true);

      await multiOwnable.renounceOwnership({ from: THIRD });
      assert.equal(await multiOwnable.isOwner(THIRD), false);
    });
  });

  describe("getOwners()", () => {
    it("should correctly set the owner after inizialization", async () => {
      assert.equal(await multiOwnable.getOwners(), FIRST);
    });
  });

  describe("isOwner()", () => {
    it("should correctly check the initial owner", async () => {
      assert.equal(await multiOwnable.isOwner(FIRST), true);
    });

    it("should return false for not owner", async () => {
      assert.equal(await multiOwnable.isOwner(SECOND), false);
    });
  });
});
