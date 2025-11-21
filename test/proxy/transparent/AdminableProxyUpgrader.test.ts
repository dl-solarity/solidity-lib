import { expect } from "chai";
import hre from "hardhat";

import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { Reverter } from "@test-helpers";

import type { AdminableProxy, AdminableProxyUpgrader, ERC20Mock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("AdminableProxyUpgrader", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let OWNER: HardhatEthersSigner;
  let SECOND: HardhatEthersSigner;

  let adminableProxyUpgrader: AdminableProxyUpgrader;
  let token: ERC20Mock;
  let proxy: AdminableProxy;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const AdminableProxyUpgrader = await ethers.getContractFactory("AdminableProxyUpgrader");
    const AdminableProxy = await ethers.getContractFactory("AdminableProxy");

    token = await ERC20Mock.deploy("mock", "mock", 18);

    adminableProxyUpgrader = await AdminableProxyUpgrader.deploy(OWNER);
    proxy = await AdminableProxy.deploy(await token.getAddress(), await adminableProxyUpgrader.getAddress(), "0x");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await expect(
        adminableProxyUpgrader.connect(SECOND).upgrade(await proxy.getAddress(), await proxy.getAddress(), "0x"),
      )
        .to.be.revertedWithCustomError(adminableProxyUpgrader, "OwnableUnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      expect(await adminableProxyUpgrader.getImplementation(await proxy.getAddress())).to.equal(
        await token.getAddress(),
      );
    });
  });
});
