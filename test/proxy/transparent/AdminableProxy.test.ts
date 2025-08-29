import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { Reverter } from "@test-helpers";

import { AdminableProxy, AdminableProxyUpgrader, ERC20Mock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("AdminableProxy", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let OWNER: HardhatEthersSigner;
  let PROXY_UPGRADER: HardhatEthersSigner;

  let proxy: AdminableProxy;
  let tokenProxy: ERC20Mock;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const AdminableProxyUpgrader = await ethers.getContractFactory("AdminableProxyUpgrader");
    const AdminableProxy = await ethers.getContractFactory("AdminableProxy");

    const token: ERC20Mock = await ERC20Mock.deploy("mock", "mock", 18);

    const adminableProxyUpgrader: AdminableProxyUpgrader = await AdminableProxyUpgrader.deploy(OWNER);
    proxy = await AdminableProxy.deploy(await token.getAddress(), await adminableProxyUpgrader.getAddress(), "0x");

    tokenProxy = await ethers.getContractAt("ERC20Mock", await proxy.getAddress());

    await networkHelpers.impersonateAccount(await adminableProxyUpgrader.getAddress());
    PROXY_UPGRADER = await ethers.provider.getSigner(await adminableProxyUpgrader.getAddress());
    await networkHelpers.setBalance(await PROXY_UPGRADER.getAddress(), ethers.parseEther("1"));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("delegated functions", () => {
    const AMOUNT = 10;

    it("proxy admin cannot call delegated functions", async () => {
      await expect(tokenProxy.connect(PROXY_UPGRADER).mint(OWNER.address, AMOUNT))
        .to.be.revertedWithCustomError(proxy, "ProxyDeniedAdminAccess")
        .withArgs();
    });

    it("everyone except proxy admin can call delegated functions", async () => {
      await tokenProxy.mint(OWNER.address, AMOUNT);

      expect(await tokenProxy.balanceOf(OWNER.address)).to.equal(AMOUNT);
    });
  });
});
