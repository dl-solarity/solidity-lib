import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { ProxyUpgrader, TransparentUpgradeableProxy, ERC20Mock } from "@ethers-v6";

describe("ProxyUpgrader", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let proxyUpgrader: ProxyUpgrader;
  let token: ERC20Mock;
  let proxy: TransparentUpgradeableProxy;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const ProxyUpgrader = await ethers.getContractFactory("ProxyUpgrader");
    const TransparentUpgradeableProxy = await ethers.getContractFactory("TransparentUpgradeableProxy");

    token = await ERC20Mock.deploy("mock", "mock", 18);
    proxyUpgrader = await ProxyUpgrader.deploy();
    proxy = await TransparentUpgradeableProxy.deploy(await token.getAddress(), await proxyUpgrader.getAddress(), "0x");
  });

  afterEach(reverter.revert);

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await expect(
        proxyUpgrader.connect(SECOND).upgrade(await proxy.getAddress(), await proxy.getAddress(), "0x")
      ).to.be.revertedWith("ProxyUpgrader: not an owner");
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      expect(await proxyUpgrader.getImplementation(await proxy.getAddress())).to.equal(await token.getAddress());
    });

    it("should not get implementation", async () => {
      await expect(proxyUpgrader.getImplementation(await token.getAddress())).to.be.revertedWith(
        "ProxyUpgrader: not a proxy"
      );
    });

    it("only owner should get implementation", async () => {
      await expect(proxyUpgrader.connect(SECOND).getImplementation(await proxy.getAddress())).to.be.revertedWith(
        "ProxyUpgrader: not an owner"
      );
    });
  });
});
