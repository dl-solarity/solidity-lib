import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { ERC20UpgradeableMock } from "@ethers-v6";

const { ethers } = await hre.network.connect();

describe("DeployerGuard", () => {
  let FIRST: HardhatEthersSigner;
  let SECOND: HardhatEthersSigner;

  let mock: ERC20UpgradeableMock;

  beforeEach("setup", async () => {
    [FIRST, SECOND] = await ethers.getSigners();

    const ERC20UpgradeableMock = await ethers.getContractFactory("ERC20UpgradeableMock");
    mock = await ERC20UpgradeableMock.deploy();
  });

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
