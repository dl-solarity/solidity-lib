import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { MultiOwnableMock } from "@ethers-v6";

describe("MultiOwnable", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

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
    it("should not initialize twice", async () => {
      await expect(multiOwnable.mockInit()).to.be.revertedWith("Initializable: contract is not initializing");
      await expect(multiOwnable.__MultiOwnableMock_init()).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await expect(multiOwnable.connect(SECOND).addOwners([THIRD])).to.be.revertedWith(
        "MultiOwnable: caller is not the owner"
      );

      await multiOwnable.addOwners([THIRD]);

      await expect(multiOwnable.connect(SECOND).removeOwners([THIRD])).to.be.revertedWith(
        "MultiOwnable: caller is not the owner"
      );
      await expect(multiOwnable.connect(SECOND).renounceOwnership()).to.be.revertedWith(
        "MultiOwnable: caller is not the owner"
      );
    });
  });

  describe("addOwners()", () => {
    it("should correctly add owners", async () => {
      await multiOwnable.addOwners([SECOND, THIRD]);

      expect(await multiOwnable.isOwner(SECOND)).to.be.true;
      expect(await multiOwnable.isOwner(THIRD)).to.be.true;
    });

    it("should not add null address", async () => {
      await expect(multiOwnable.addOwners([ZERO_ADDR])).to.be.revertedWith(
        "MultiOwnable: zero address can not be added"
      );
    });
  });

  describe("removeOwners()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([SECOND]);
      await multiOwnable.removeOwners([SECOND, THIRD]);

      expect(await multiOwnable.isOwner(SECOND)).to.be.false;
      expect(await multiOwnable.isOwner(FIRST)).to.be.true;
    });
  });

  describe("renounceOwnership()", () => {
    it("should correctly remove the owner", async () => {
      await multiOwnable.addOwners([THIRD]);
      expect(await multiOwnable.isOwner(THIRD)).to.be.true;

      await multiOwnable.renounceOwnership({ from: THIRD });
      expect(await multiOwnable.isOwner(THIRD)).to.be.false;
    });
  });

  describe("getOwners()", () => {
    it("should correctly set the owner after inizialization", async () => {
      expect(await multiOwnable.getOwners()).to.equal(FIRST);
    });
  });

  describe("isOwner()", () => {
    it("should correctly check the initial owner", async () => {
      expect(await multiOwnable.isOwner(FIRST)).to.be.true;
    });

    it("should return false for not owner", async () => {
      expect(await multiOwnable.isOwner(SECOND)).to.be.false;
    });
  });
});
