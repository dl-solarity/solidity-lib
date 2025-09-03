import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { MultiOwnablePoolContractsRegistryMock } from "@ethers-v6";

const { ethers } = await hre.network.connect();

describe("MultiOwnablePoolContractsRegistry", () => {
  let SECOND: HardhatEthersSigner;

  let poolContractsRegistry: MultiOwnablePoolContractsRegistryMock;

  beforeEach("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const MultiOwnablePoolContractsRegistryMock = await ethers.getContractFactory(
      "MultiOwnablePoolContractsRegistryMock",
    );
    poolContractsRegistry = await MultiOwnablePoolContractsRegistryMock.deploy();

    await poolContractsRegistry.__AMultiOwnablePoolContractsRegistry_init();
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(poolContractsRegistry.__AMultiOwnablePoolContractsRegistry_init())
        .to.be.revertedWithCustomError(poolContractsRegistry, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(poolContractsRegistry.connect(SECOND).setNewImplementations([], []))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPools("", 0, 0))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);

      await expect(poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPoolsWithData("", "0x", 0, 0))
        .to.be.revertedWithCustomError(poolContractsRegistry, "UnauthorizedAccount")
        .withArgs(SECOND.address);
    });
  });

  describe("coverage", () => {
    it("should call these methods", async () => {
      await expect(poolContractsRegistry.setNewImplementations([""], [await SECOND.getAddress()])).to.be.revert(ethers);

      await expect(poolContractsRegistry.injectDependenciesToExistingPools("", 0, 0)).to.be.revert(ethers);

      await expect(poolContractsRegistry.injectDependenciesToExistingPoolsWithData("", "0x", 0, 0)).to.be.revert(
        ethers,
      );
    });
  });
});
