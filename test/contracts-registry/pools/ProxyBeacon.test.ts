import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { ProxyBeacon, ERC20Mock } from "@ethers-v6";

describe("ProxyBeacon", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let proxyBeacon: ProxyBeacon;
  let token: ERC20Mock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ProxyBeacon = await ethers.getContractFactory("ProxyBeacon");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    proxyBeacon = await ProxyBeacon.deploy();
    token = await ERC20Mock.deploy("mock", "mock", 18);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("functions", () => {
    it("should upgrade", async () => {
      expect(await proxyBeacon.implementation()).to.equal(ZERO_ADDR);

      await proxyBeacon.upgrade(await token.getAddress());

      expect(await proxyBeacon.implementation()).to.equal(await token.getAddress());
    });

    it("should not upgrade to non-contract", async () => {
      await expect(proxyBeacon.upgrade(SECOND)).to.be.revertedWith("ProxyBeacon: not a contract");
    });

    it("only owner should upgrade", async () => {
      await expect(proxyBeacon.connect(SECOND).upgrade(await token.getAddress())).to.be.revertedWith(
        "ProxyBeacon: not an owner"
      );
    });
  });
});
