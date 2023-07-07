const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../scripts/utils/constants");

const truffleAssert = require("truffle-assertions");

const SBTMock = artifacts.require("SBTMock");

const name = "testName";
const symbol = "TS";
const baseTokenURI = "https://ipfs.io/ipfs/QmUvdwBdr1CcfLJhxyWZiaMYM7kCciCuXx1V4EKSPWUGzu";

describe.only("SBT", () => {
  let FIRST;
  let SECOND;

  let sbt;

  before("setup", async () => {
    FIRST = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    sbt = await SBTMock.new();

    await sbt.__WhitelistedSBTMock_init(name, symbol, baseTokenURI, [FIRST]);
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(
        sbt.mockInit(name, symbol, baseTokenURI, []),
        "Initializable: contract is not initializing"
      );
      await truffleAssert.reverts(
        sbt.__SBTMock_init(name, symbol, baseTokenURI),
        "Initializable: contract is not initializing"
      );
      await truffleAssert.reverts(
        sbt.__WhitelistedSBTMock_init(name, symbol, baseTokenURI, []),
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("init parameters", () => {
    it("should correctly init", async () => {
      assert.equal(await sbt.name(), name);
      assert.equal(await sbt.symbol(), symbol);
      assert.equal(await sbt.baseURI(), baseTokenURI);
      assert.equal(await sbt.isWhitelisted(FIRST), true);
    });
  });

  describe("addToWhitelist()", () => {
    it("should correctly add addresses to whitelist", async () => {
      await sbt.addToWhitelist([SECOND]);

      assert.equal(await sbt.isWhitelisted(SECOND), true);
    });
  });

  describe("deleteFromWhitelist()", () => {
    it("should correctly remove addresses from whitelist", async () => {
      await sbt.deleteFromWhitelist([FIRST]);

      assert.equal(await sbt.isWhitelisted(FIRST), false);
    });
  });

  describe("mint()", () => {
    it("should correctly mint if available", async () => {
      await sbt.mint(FIRST, 0);

      assert.equal(await sbt.balanceOf(FIRST), 1);
      assert.equal(await sbt.ownerOf(0), FIRST);
      assert.equal(await sbt.isTokenExist(0), true);
      assert.equal(await sbt.tokenURI(0), baseTokenURI + "0");
    });

    it("should not mint if not available", async () => {
      await truffleAssert.reverts(sbt.mint(FIRST, 0, { from: SECOND }), "WhitelistedSBT: not available to claim");
    });

    it("should not mint to null address", async () => {
      await truffleAssert.reverts(sbt.mint(ZERO_ADDR, 1), "SBT: invalidReceiver(address(0)");
    });

    it("should not mint token that exist", async () => {
      await sbt.mint(FIRST, 1);
      await truffleAssert.reverts(sbt.mint(FIRST, 1), "SBT: already exist tokenId");
    });
  });

  describe("burn()", () => {
    it("should correctly burn own token", async () => {
      await sbt.mint(FIRST, 0);

      await sbt.burnMock(0);

      assert.equal(await sbt.balanceOf(FIRST), 0);
      assert.equal(await sbt.ownerOf(0), ZERO_ADDR);
      assert.equal(await sbt.isTokenExist(0), false);
    });

    it("should not burn sbt that don't exist", async () => {
      await truffleAssert.reverts(sbt.burnMock(1), "SBT: sbt you want to burn don't exist");
    });
  });

  describe("setTokenURI()", () => {
    it("should correctly set uri for existent token", async () => {
      await sbt.mint(FIRST, 0);
      await sbt.setTokenURI(0, "test");
      assert.equal(await sbt.tokenURI(0), "test");
    });

    it("should not set uri for non-existent token", async () => {
      await truffleAssert.reverts(sbt.setTokenURI(1, ""), "SBT: nonexistent tokenId");
    });

    it("should correctly return empty uri", async () => {
      await sbt.setBaseTokenURI("");
      await sbt.mint(FIRST, 0);

      assert.equal(await sbt.tokenURI(0), "");
    });
  });
});
