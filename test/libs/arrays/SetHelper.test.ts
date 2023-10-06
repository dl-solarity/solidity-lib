import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { SetHelperMock } from "@ethers-v6";

describe("SetHelper", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let mock: SetHelperMock;

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const SetHelperMock = await ethers.getContractFactory("SetHelperMock");
    mock = await SetHelperMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("add", () => {
    it("should add to address set", async () => {
      await mock.addToAddressSet([FIRST.address, SECOND.address]);

      expect(await mock.getAddressSet()).to.deep.equal([FIRST.address, SECOND.address]);
    });

    it("should add to uint set", async () => {
      await mock.addToUintSet([1]);

      expect(await mock.getUintSet()).to.deep.equal([1n]);
    });

    it("should add to string set", async () => {
      await mock.addToStringSet(["1", "2", "3"]);

      expect(await mock.getStringSet()).to.deep.equal(["1", "2", "3"]);
    });
  });

  describe("remove", () => {
    it("should remove from address set", async () => {
      await mock.addToAddressSet([FIRST.address, SECOND.address]);
      await mock.removeFromAddressSet([SECOND.address, THIRD.address]);

      expect(await mock.getAddressSet()).to.deep.equal([FIRST.address]);
    });

    it("should remove from uint set", async () => {
      await mock.addToUintSet([1]);
      await mock.removeFromUintSet([1]);

      expect(await mock.getUintSet()).to.deep.equal([]);
    });

    it("should remove from string set", async () => {
      await mock.addToStringSet(["1", "2", "3"]);
      await mock.removeFromStringSet(["1", "4"]);

      expect(await mock.getStringSet()).to.deep.equal(["3", "2"]);
    });
  });
});
