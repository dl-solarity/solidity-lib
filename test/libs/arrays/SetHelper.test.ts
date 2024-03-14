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

  describe("strictAdd", () => {
    it("should not strict add to address set if element already exists", async () => {
      await expect(mock.strictAddToAddressSet([FIRST.address, FIRST.address])).to.be.revertedWith(
        "SetHelper: element already exists",
      );
    });

    it("should not strict add to uint set if element already exists", async () => {
      await expect(mock.strictAddToUintSet([1, 1])).to.be.revertedWith("SetHelper: element already exists");
    });

    it("should strict add to string set if element already exists", async () => {
      await expect(mock.strictAddToStringSet(["1", "1"])).to.be.revertedWith("SetHelper: element already exists");
    });

    it("should strict add to address set", async () => {
      await mock.strictAddToAddressSet([FIRST.address, SECOND.address]);

      expect(await mock.getAddressSet()).to.deep.equal([FIRST.address, SECOND.address]);
    });

    it("should strict add to uint set", async () => {
      await mock.strictAddToUintSet([1]);

      expect(await mock.getUintSet()).to.deep.equal([1n]);
    });

    it("should strict add to string set", async () => {
      await mock.strictAddToStringSet(["1", "2", "3"]);

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

  describe("remove", () => {
    it("should not strict remove from address set if no such element", async () => {
      await mock.strictAddToAddressSet([FIRST.address, SECOND.address]);

      await expect(mock.strictRemoveFromAddressSet([SECOND.address, SECOND.address])).to.be.revertedWith(
        "SetHelper: no such element",
      );
    });

    it("should not strict remove from uint set if no such element", async () => {
      await mock.strictAddToUintSet([1]);

      await expect(mock.strictRemoveFromUintSet([1, 1])).to.be.revertedWith("SetHelper: no such element");
    });

    it("should not strict remove from string set if no such element", async () => {
      await mock.strictAddToStringSet(["1", "2", "3"]);

      await expect(mock.strictRemoveFromStringSet(["1", "1"])).to.be.revertedWith("SetHelper: no such element");
    });

    it("should strict remove from address set", async () => {
      await mock.strictAddToAddressSet([FIRST.address, SECOND.address]);
      await mock.strictRemoveFromAddressSet([SECOND.address]);

      expect(await mock.getAddressSet()).to.deep.equal([FIRST.address]);
    });

    it("should strict remove from uint set", async () => {
      await mock.strictAddToUintSet([1]);
      await mock.strictRemoveFromUintSet([1]);

      expect(await mock.getUintSet()).to.deep.equal([]);
    });

    it("should strict remove from string set", async () => {
      await mock.strictAddToStringSet(["1", "2", "3"]);
      await mock.strictRemoveFromStringSet(["1"]);

      expect(await mock.getStringSet()).to.deep.equal(["3", "2"]);
    });
  });
});
