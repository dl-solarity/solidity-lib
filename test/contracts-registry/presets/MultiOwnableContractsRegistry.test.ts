import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { Reverter } from "@test-helpers";

import { MultiOwnableContractsRegistry } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("MultiOwnableContractsRegistry", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let SECOND: HardhatEthersSigner;

  let contractsRegistry: MultiOwnableContractsRegistry;

  before("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const MultiOwnableContractsRegistry = await ethers.getContractFactory("MultiOwnableContractsRegistry");
    contractsRegistry = await MultiOwnableContractsRegistry.deploy();

    await contractsRegistry.__MultiOwnableContractsRegistry_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(contractsRegistry.__MultiOwnableContractsRegistry_init())
        .to.be.revertedWithCustomError(contractsRegistry, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(contractsRegistry.connect(SECOND).injectDependencies(""))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).injectDependenciesWithData("", "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).upgradeContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).upgradeContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).addProxyContractAndCall("", ethers.ZeroAddress, "0x"))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).justAddProxyContract("", ethers.ZeroAddress))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(contractsRegistry.connect(SECOND).removeContract(""))
        .to.be.revertedWithCustomError(contractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);
    });
  });

  describe("coverage", () => {
    it("should call these methods", async () => {
      await expect(contractsRegistry.injectDependencies("")).to.be.revert(ethers);

      await expect(contractsRegistry.injectDependenciesWithData("", "0x")).to.be.revert(ethers);

      await expect(contractsRegistry.upgradeContract("", ethers.ZeroAddress)).to.be.revert(ethers);

      await expect(contractsRegistry.upgradeContractAndCall("", ethers.ZeroAddress, "0x")).to.be.revert(ethers);

      await expect(contractsRegistry.addContract("", ethers.ZeroAddress)).to.be.revert(ethers);

      await expect(contractsRegistry.addProxyContract("", ethers.ZeroAddress)).to.be.revert(ethers);

      await expect(contractsRegistry.addProxyContractAndCall("", ethers.ZeroAddress, "0x")).to.be.revert(ethers);

      await expect(contractsRegistry.justAddProxyContract("", ethers.ZeroAddress)).to.be.revert(ethers);

      await expect(contractsRegistry.removeContract("")).to.be.revert(ethers);
    });
  });
});
