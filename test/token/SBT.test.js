const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../scripts/utils/constants");

const truffleAssert = require("truffle-assertions");

const SBTMock = artifacts.require("SBTMock");

const name = "testName";
const symbol = "TS";
const baseTokenURI = "https://ipfs.io/ipfs/QmUvdwBdr1CcfLJhxyWZiaMYM7kCciCuXx1V4EKSPWUGzu";

describe("SBT", () => {
  let FIRST;
  let SECOND;

  let sbt;

  before("setup", async () => {
    FIRST = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    sbt = await SBTMock.new();

    await sbt.__OwnableSBT_init(name, symbol, baseTokenURI);
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(
        sbt.mockInit(name, symbol, baseTokenURI),
        "Initializable: contract is not initializing"
      );
      await truffleAssert.reverts(
        sbt.__OwnableSBT_init(name, symbol, baseTokenURI),
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await truffleAssert.reverts(sbt.addToAvailable([SECOND], { from: SECOND }), "Ownable: caller is not the owner");

      await truffleAssert.reverts(
        sbt.deleteFromAvailable([FIRST], { from: SECOND }),
        "Ownable: caller is not the owner"
      );

      await truffleAssert.reverts(sbt.setBaseTokenURI("", { from: SECOND }), "Ownable: caller is not the owner");
    });
  });

  describe("init parameters", () => {
    it("should correctly init", async () => {
      assert.equal(await sbt.name(), name);
      assert.equal(await sbt.symbol(), symbol);
      assert.equal(await sbt.getBaseTokenURI(), baseTokenURI);
    });
  });

  describe("addToAvailable()", () => {
    it("should correctly add addresses", async () => {
      await sbt.addToAvailable([SECOND, FIRST]);

      assert.equal(await sbt.ifAvailable(SECOND), true);
      assert.equal(await sbt.ifAvailable(FIRST), true);
    });
  });

  describe("deleteFromAvailable()", () => {
    it("should correctly remove addresses", async () => {
      await sbt.addToAvailable([SECOND]);

      await sbt.deleteFromAvailable([SECOND]);

      assert.equal(await sbt.ifAvailable(SECOND), false);
    });
  });

  describe("setBaseTokenURI()", () => {
    it("should correctly set the base URI", async () => {
      await sbt.setBaseTokenURI("testURI");

      assert.equal(await sbt.getBaseTokenURI(), "testURI");
    });
  });

  describe("mint()", () => {
    it("should correctly mint if available", async () => {
      await sbt.addToAvailable([FIRST]);

      await sbt.mint();

      assert.equal(await sbt.balanceOf(FIRST), 1);
      assert.equal(await sbt.ownerOf(0), FIRST);
      assert.equal(await sbt.isTokenExist(0), true);
      assert.equal(await sbt.tokenURI(0), baseTokenURI + "0");
    });

    it("should not mint if not available", async () => {
      await truffleAssert.reverts(sbt.mint(), "OwnableSBT: not available to claim");
    });
  });

  describe("burn()", () => {
    it("should correctly burn own token", async () => {
      await sbt.addToAvailable([FIRST]);
      await sbt.mint();

      await sbt.burn(0);

      assert.equal(await sbt.balanceOf(FIRST), 0);
      assert.equal(await sbt.ownerOf(0), ZERO_ADDR);
      assert.equal(await sbt.isTokenExist(0), false);
    });

    it("only owner of sbt can burn it", async () => {
      await sbt.addToAvailable([FIRST]);
      await sbt.mint();

      await truffleAssert.reverts(sbt.burn(0, { from: SECOND }), "OwnableSBT: can't burn another user's nft");
    });
  });

  describe("internal mint()", () => {
    it("should correctly mint", async () => {
      await sbt.mint(FIRST, 1);

      assert.equal(await sbt.balanceOf(FIRST), 1);
      assert.equal(await sbt.ownerOf(1), FIRST);
      assert.equal(await sbt.isTokenExist(1), true);
    });

    it("should not mint to null address", async () => {
      await truffleAssert.reverts(sbt.mint(ZERO_ADDR, 1), "SBT: invalidReceiver(address(0)");
    });

    it("should not mint token that exist", async () => {
      await sbt.mint(FIRST, 1);
      await truffleAssert.reverts(sbt.mint(FIRST, 1), "SBT: already exist tokenId");
    });
  });

  describe("abstract burn()", () => {
    it("should not burn sbt that don't exist", async () => {
      await truffleAssert.reverts(sbt.burnMock(1), "SBT: sbt you want to burn don't exist");
    });
  });

  describe("setTokenURI()", () => {
    it("should correctly set uri for existent token", async () => {
      await sbt.addToAvailable([FIRST]);
      await sbt.mint();
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
