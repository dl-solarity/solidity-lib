import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { PermanentOwnableMock } from "@ethers-v6";

describe("PermanentOwnable", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let OTHER: SignerWithAddress;

  let permanentOwnable: PermanentOwnableMock;

  before("setup", async () => {
    [OWNER, OTHER] = await ethers.getSigners();

    const permanentOwnableMock = await ethers.getContractFactory("PermanentOwnableMock");
    permanentOwnable = await permanentOwnableMock.deploy(OWNER);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("PermanentOwnable", () => {
    it("should set the correct owner", async () => {
      expect(await permanentOwnable.owner()).to.equal(OWNER.address);
    });

    it("should reject zero address during the owner initialization", async () => {
      const permanentOwnableMock = await ethers.getContractFactory("PermanentOwnableMock");

      await expect(permanentOwnableMock.deploy(ZERO_ADDR)).to.be.revertedWith(
        "PermanentOwnable: zero address can not be the owner",
      );
    });

    it("only owner should call this function", async () => {
      expect(await permanentOwnable.connect(OWNER).onlyOwnerMethod()).to.emit(permanentOwnable, "ValidOwner");
      await expect(permanentOwnable.connect(OTHER).onlyOwnerMethod()).to.be.revertedWith(
        "PermanentOwnable: caller is not the owner",
      );
    });
  });
});
