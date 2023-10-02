const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../scripts/utils/constants");

const truffleAssert = require("truffle-assertions");

const SBTMock = artifacts.require("SBTMock");

describe("SBT", () => {
  const name = "testName";
  const symbol = "TS";

  let FIRST;

  let sbt;

  before("setup", async () => {
    FIRST = await accounts(0);
  });

  beforeEach("setup", async () => {
    sbt = await SBTMock.new();

    await sbt.__SBTMock_init(name, symbol);
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(sbt.__SBTMock_init(name, symbol), "Initializable: contract is already initialized");
      await truffleAssert.reverts(sbt.mockInit(name, symbol), "Initializable: contract is not initializing");
    });
  });

  describe("init parameters", () => {
    it("should correctly init", async () => {
      assert.equal(await sbt.name(), name);
      assert.equal(await sbt.symbol(), symbol);
    });
  });

  describe("mint()", () => {
    it("should correctly mint", async () => {
      await sbt.mint(FIRST, 1337);

      assert.isTrue(await sbt.tokenExists(1337));

      assert.equal(await sbt.balanceOf(FIRST), 1);
      assert.equal(await sbt.ownerOf(1337), FIRST);

      assert.equal(await sbt.tokenOf(FIRST, 0), 1337);
      assert.deepEqual(
        (await sbt.tokensOf(FIRST)).map((e) => e.toNumber()),
        [1337]
      );

      assert.equal(await sbt.tokenURI(1337), "");
    });

    it("should not mint to null address", async () => {
      await truffleAssert.reverts(sbt.mint(ZERO_ADDR, 1), "SBT: address(0) receiver");
    });

    it("should not mint token twice", async () => {
      await sbt.mint(FIRST, 1);

      await truffleAssert.reverts(sbt.mint(FIRST, 1), "SBT: token already exists");
    });
  });

  describe("burn()", () => {
    it("should correctly burn", async () => {
      await sbt.mint(FIRST, 1337);

      await sbt.burn(1337);

      assert.isFalse(await sbt.tokenExists(0));

      assert.equal(await sbt.balanceOf(FIRST), 0);
      assert.equal(await sbt.ownerOf(0), ZERO_ADDR);

      assert.deepEqual(await sbt.tokensOf(FIRST), []);
    });

    it("should not burn SBT that doesn't exist", async () => {
      await truffleAssert.reverts(sbt.burn(1337), "SBT: token doesn't exist");
    });
  });

  describe("setTokenURI()", () => {
    it("should correctly set token URI", async () => {
      await sbt.mint(FIRST, 1337);
      await sbt.setTokenURI(1337, "test");

      assert.equal(await sbt.tokenURI(1337), "test");
    });

    it("should not set uri for non-existent token", async () => {
      await truffleAssert.reverts(sbt.setTokenURI(1337, ""), "SBT: token doesn't exist");
    });

    it("should reset token URI if token is burnder", async () => {
      await sbt.mint(FIRST, 1337);
      await sbt.setTokenURI(1337, "test");

      await sbt.burn(1337);

      assert.equal(await sbt.tokenURI(1337), "");
    });
  });

  describe("setBaseURI()", () => {
    it("should correctly set base URI", async () => {
      await sbt.setBaseURI("test");

      assert.equal(await sbt.baseURI(), "test");
      assert.equal(await sbt.tokenURI(1337), "test1337");
    });

    it("should override base URI", async () => {
      await sbt.setBaseURI("test");

      await sbt.mint(FIRST, 1337);
      await sbt.setTokenURI(1337, "test");

      assert.equal(await sbt.tokenURI(1337), "test");
    });
  });
});
