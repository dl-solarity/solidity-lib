import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { MultiOwnablePoolContractsRegistryMock } from "@ethers-v6";

describe("MultiOwnablePoolContractsRegistry", () => {
  const reverter = new Reverter();

  let SECOND: SignerWithAddress;

  let poolContractsRegistry: MultiOwnablePoolContractsRegistryMock;

  before("setup", async () => {
    [, SECOND] = await ethers.getSigners();

    const MultiOwnablePoolContractsRegistryMock = await ethers.getContractFactory(
      "MultiOwnablePoolContractsRegistryMock"
    );
    poolContractsRegistry = await MultiOwnablePoolContractsRegistryMock.deploy();

    await poolContractsRegistry.__MultiOwnablePoolContractsRegistry_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(poolContractsRegistry.__MultiOwnablePoolContractsRegistry_init()).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await expect(poolContractsRegistry.connect(SECOND).setNewImplementations([], [])).to.be.revertedWith(
        "MultiOwnable: caller is not the owner"
      );

      await expect(
        poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPools("", 0, 0)
      ).to.be.revertedWith("MultiOwnable: caller is not the owner");

      await expect(
        poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPoolsWithData("", "0x", 0, 0)
      ).to.be.revertedWith("MultiOwnable: caller is not the owner");
    });
  });

  describe("coverage", () => {
    it("should call these methods", async () => {
      await expect(poolContractsRegistry.setNewImplementations([""], [await SECOND.getAddress()])).to.be.reverted;

      await expect(poolContractsRegistry.injectDependenciesToExistingPools("", 0, 0)).to.be.reverted;

      await expect(poolContractsRegistry.injectDependenciesToExistingPoolsWithData("", "0x", 0, 0)).to.be.reverted;
    });
  });
});
