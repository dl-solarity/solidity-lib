import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { TransparentProxyUpgrader, TransparentUpgradeableProxy, ERC20Mock } from "@ethers-v6";

describe("TransparentProxyUpgrader", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let proxyUpgrader: TransparentProxyUpgrader;
  let token: ERC20Mock;
  let proxy: TransparentUpgradeableProxy;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const TransparentProxyUpgrader = await ethers.getContractFactory("TransparentProxyUpgrader");
    const TransparentUpgradeableProxy = await ethers.getContractFactory("TransparentUpgradeableProxy");

    token = await ERC20Mock.deploy("mock", "mock", 18);
    proxyUpgrader = await TransparentProxyUpgrader.deploy();
    proxy = await TransparentUpgradeableProxy.deploy(await token.getAddress(), await proxyUpgrader.getAddress(), "0x");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await expect(
        proxyUpgrader.connect(SECOND).upgrade(await proxy.getAddress(), await proxy.getAddress(), "0x"),
      ).to.be.revertedWith("TransparentProxyUpgrader: not an owner");
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      expect(await proxyUpgrader.getImplementation(await proxy.getAddress())).to.equal(await token.getAddress());
    });

    it("should not get implementation", async () => {
      await expect(proxyUpgrader.getImplementation(await token.getAddress())).to.be.revertedWith(
        "TransparentProxyUpgrader: not a proxy",
      );
    });

    it("only owner should get implementation", async () => {
      await expect(proxyUpgrader.connect(SECOND).getImplementation(await proxy.getAddress())).to.be.revertedWith(
        "TransparentProxyUpgrader: not an owner",
      );
    });
  });
});
