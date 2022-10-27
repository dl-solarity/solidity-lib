const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../scripts/utils/constants");
const truffleAssert = require("truffle-assertions");

const ProxyBeacon = artifacts.require("ProxyBeacon");
const ERC20Mock = artifacts.require("ERC20Mock");

ProxyBeacon.numberFormat = "BigNumber";
ERC20Mock.numberFormat = "BigNumber";

describe("ProxyUpgrader", () => {
  let OWNER;
  let SECOND;

  let proxyBeacon;
  let token;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    token = await ERC20Mock.new("mock", "mock", 18);
    proxyBeacon = await ProxyBeacon.new();
  });

  describe("functions", () => {
    it("should upgrade", async () => {
      assert.equal(await proxyBeacon.implementation(), ZERO_ADDR);

      await proxyBeacon.upgrade(token.address);

      assert.equal(await proxyBeacon.implementation(), token.address);
    });

    it("should not upgrade to non-contract", async () => {
      await truffleAssert.reverts(proxyBeacon.upgrade(SECOND), "ProxyBeacon: Not a contract");
    });

    it("only owner should upgrade", async () => {
      await truffleAssert.reverts(proxyBeacon.upgrade(token.address, { from: SECOND }), "ProxyBeacon: Not an owner");
    });
  });
});
