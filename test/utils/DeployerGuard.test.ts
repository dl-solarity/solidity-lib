import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";

import type { ERC20UpgradeableMock } from "@ethers-v6";

describe("DeployerGuard", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let mock: ERC20UpgradeableMock;

  before("setup", async () => {
    [FIRST, SECOND] = await ethers.getSigners();

    const ERC20UpgradeableMock = await ethers.getContractFactory("ERC20UpgradeableMock");
    mock = await ERC20UpgradeableMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("onlyDeployer", () => {
    it("should revert if trying to call initializer by non-deployer", async () => {
      await expect(mock.connect(SECOND).__ERC20UpgradeableMock_init("Test", "TST", 18))
        .to.be.revertedWithCustomError(mock, "OnlyDeployer")
        .withArgs(SECOND.address);
    });

    it("should allow to call initializer by deployer", async () => {
      await mock.connect(FIRST).__ERC20UpgradeableMock_init("Test", "TST", 18);

      expect(await mock.name()).to.equal("Test");
      expect(await mock.symbol()).to.equal("TST");
      expect(await mock.decimals()).to.equal(18);
    });
  });
});
