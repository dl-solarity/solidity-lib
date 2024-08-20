import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import { TransparentProxyUpgrader, SolarityTransparentProxy, ERC20Mock } from "@ethers-v6";

describe("TransparentProxyUpgrader", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let transparentProxyUpgrader: TransparentProxyUpgrader;
  let token: ERC20Mock;
  let proxy: SolarityTransparentProxy;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const TransparentProxyUpgrader = await ethers.getContractFactory("TransparentProxyUpgrader");
    const SolarityTransparentProxy = await ethers.getContractFactory("SolarityTransparentProxy");

    token = await ERC20Mock.deploy("mock", "mock", 18);

    transparentProxyUpgrader = await TransparentProxyUpgrader.deploy();
    proxy = await SolarityTransparentProxy.deploy(
      await token.getAddress(),
      await transparentProxyUpgrader.getAddress(),
      "0x",
    );

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("upgrade", () => {
    it("only owner should upgrade", async () => {
      await expect(
        transparentProxyUpgrader.connect(SECOND).upgrade(await proxy.getAddress(), await proxy.getAddress(), "0x"),
      )
        .to.be.revertedWithCustomError(transparentProxyUpgrader, "UnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("getImplementation", () => {
    it("should get implementation", async () => {
      expect(await transparentProxyUpgrader.getImplementation(await proxy.getAddress())).to.equal(
        await token.getAddress(),
      );
    });

    it("should not get implementation", async () => {
      await expect(transparentProxyUpgrader.getImplementation(await token.getAddress()))
        .to.be.revertedWithCustomError(transparentProxyUpgrader, "AddressNotAProxy")
        .withArgs(await token.getAddress());
    });
  });
});
