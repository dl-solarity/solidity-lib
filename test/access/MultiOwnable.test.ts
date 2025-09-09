import { expect } from "chai";
import hre from "hardhat";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { Reverter } from "@test-helpers";

import { MultiOwnableMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("MultiOwnable", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let FIRST: HardhatEthersSigner;
  let SECOND: HardhatEthersSigner;
  let THIRD: HardhatEthersSigner;

  let multiOwnable: MultiOwnableMock;

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const MultiOwnableMock = await ethers.getContractFactory("MultiOwnableMock");
    multiOwnable = await MultiOwnableMock.deploy();

    await multiOwnable.__MultiOwnableMock_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize", async () => {
      const multiOwnableMock = await ethers.deployContract("MultiOwnableMock");

      await expect(multiOwnableMock.__MultiOwnableMockMulti_init([]))
        .to.be.revertedWithCustomError(multiOwnable, "InvalidOwner")
        .withArgs();

      await multiOwnableMock.__MultiOwnableMockMulti_init([FIRST.address]);

      expect(await multiOwnableMock.isOwner(FIRST.address)).to.be.true;
    });

    it("should not initialize twice", async () => {
      await expect(multiOwnable.mockInit()).to.be.revertedWithCustomError(multiOwnable, "NotInitializing").withArgs();
      await expect(multiOwnable.mockMultiInit())
        .to.be.revertedWithCustomError(multiOwnable, "NotInitializing")
        .withArgs();

      await expect(multiOwnable.__MultiOwnableMock_init())
        .to.be.revertedWithCustomError(multiOwnable, "InvalidInitialization")
        .withArgs();
      await expect(multiOwnable.__MultiOwnableMockMulti_init([FIRST.address]))
        .to.be.revertedWithCustomError(multiOwnable, "InvalidInitialization")
        .withArgs();
    });

    it("only owner should call these functions", async () => {
      await expect(multiOwnable.connect(SECOND).addOwners([THIRD.address]))
        .to.be.revertedWithCustomError(multiOwnable, "UnauthorizedAccount")
        .withArgs(SECOND);

      await multiOwnable.addOwners([THIRD.address]);

      await expect(multiOwnable.connect(SECOND).removeOwners([THIRD.address]))
        .to.be.revertedWithCustomError(multiOwnable, "UnauthorizedAccount")
        .withArgs(SECOND);

      await expect(multiOwnable.connect(SECOND).renounceOwnership())
        .to.be.revertedWithCustomError(multiOwnable, "UnauthorizedAccount")
        .withArgs(SECOND);
    });
  });

  describe("addOwners()", () => {
    it("should correctly add owners", async () => {
      await multiOwnable.addOwners([SECOND.address, THIRD.address]);

      expect(await multiOwnable.isOwner(SECOND.address)).to.be.true;
      expect(await multiOwnable.isOwner(THIRD.address)).to.be.true;
    });

    it("should not add null address", async () => {
      await expect(multiOwnable.addOwners([ethers.ZeroAddress])).to.be.revertedWithCustomError(
        multiOwnable,
        "InvalidOwner",
      );
    });
  });

  describe("removeOwners()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([SECOND.address]);
      await multiOwnable.removeOwners([SECOND.address, THIRD.address]);

      expect(await multiOwnable.isOwner(SECOND.address)).to.be.false;
      expect(await multiOwnable.isOwner(FIRST.address)).to.be.true;
    });
  });

  describe("renounceOwnership()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([THIRD.address]);
      expect(await multiOwnable.isOwner(THIRD.address)).to.be.true;

      await multiOwnable.connect(THIRD).renounceOwnership();
      expect(await multiOwnable.isOwner(THIRD.address)).to.be.false;
    });
  });

  describe("getOwners()", () => {
    it("should correctly set the owner after initialization", async () => {
      expect(await multiOwnable.getOwners()).to.deep.equal([FIRST.address]);
    });
  });

  describe("isOwner()", () => {
    it("should correctly check the initial owner", async () => {
      expect(await multiOwnable.isOwner(FIRST.address)).to.be.true;
    });

    it("should return false for not owner", async () => {
      expect(await multiOwnable.isOwner(SECOND.address)).to.be.false;
    });
  });
});
