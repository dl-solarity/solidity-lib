import { ethers } from "hardhat";
import { impersonateAccount, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { TransparentProxyUpgrader, SolarityTransparentProxy, ERC20Mock } from "@ethers-v6";

describe("SolarityTransparentProxy", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let PROXY_UPGRADER: SignerWithAddress;

  let proxy: SolarityTransparentProxy;
  let tokenProxy: ERC20Mock;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const TransparentProxyUpgrader = await ethers.getContractFactory("TransparentProxyUpgrader");
    const SolarityTransparentProxy = await ethers.getContractFactory("SolarityTransparentProxy");

    const token: ERC20Mock = await ERC20Mock.deploy("mock", "mock", 18);

    const transparentProxyUpgrader: TransparentProxyUpgrader = await TransparentProxyUpgrader.deploy();
    proxy = await SolarityTransparentProxy.deploy(
      await token.getAddress(),
      await transparentProxyUpgrader.getAddress(),
      "0x",
    );

    tokenProxy = <ERC20Mock>token.attach(await proxy.getAddress());

    await impersonateAccount(await transparentProxyUpgrader.getAddress());
    PROXY_UPGRADER = await ethers.provider.getSigner(await transparentProxyUpgrader.getAddress());
    await setBalance(await PROXY_UPGRADER.getAddress(), ethers.parseEther("1"));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("delegated functions", () => {
    const AMOUNT = 10;

    it("proxy admin cannot call delegated functions", async () => {
      await expect(tokenProxy.connect(PROXY_UPGRADER).mint(OWNER.address, AMOUNT)).to.be.revertedWithCustomError(
        proxy,
        "ProxyDeniedAdminAccess",
      );
    });

    it("everyone except proxy admin can call delegated functions", async () => {
      await tokenProxy.mint(OWNER.address, AMOUNT);

      expect(await tokenProxy.balanceOf(OWNER.address)).to.equal(AMOUNT);
    });
  });
});
