const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const ProxyUpgrader = artifacts.require("ProxyUpgrader");
const ERC20Mock = artifacts.require("ERC20Mock");
const Proxy = artifacts.require("TransparentUpgradeableProxy");

ProxyUpgrader.numberFormat = "BigNumber";
ERC20Mock.numberFormat = "BigNumber";
Proxy.numberFormat = "BigNumber";

describe("ProxyUpgrader", () => {
  let OWNER;
  let SECOND;

  let proxyUpgrader;
  let token;
  let proxy;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    token = await ERC20Mock.new("mock", "mock", 18);
    proxyUpgrader = await ProxyUpgrader.new();
    proxy = await Proxy.new(token.address, proxyUpgrader.address, []);
  });

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await truffleAssert.reverts(
        proxyUpgrader.upgrade(proxy.address, proxy.address, "0x", { from: SECOND }),
        "ProxyUpgrader: Not an owner"
      );
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      assert.equal(await proxyUpgrader.getImplementation(proxy.address), token.address);
    });

    it("should not get implementation", async () => {
      await truffleAssert.reverts(proxyUpgrader.getImplementation(token.address));
    });

    it("only owner should get implementation", async () => {
      await truffleAssert.reverts(
        proxyUpgrader.getImplementation(proxy.address, { from: SECOND }),
        "ProxyUpgrader: Not an owner"
      );
    });
  });
});
