import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { wei } from "@/scripts/utils/utils";

import { AbstractValueDistributorMock } from "@ethers-v6";

describe("AbstractValueDistributor", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;
  let FOURTH: SignerWithAddress;

  let abstractValueDistributor: AbstractValueDistributorMock;

  const addSharesToAllUsers = async (shares: Array<any>) => {
    await abstractValueDistributor.addShares(FIRST, shares[0]);
    await abstractValueDistributor.addShares(SECOND, shares[1]);
    await abstractValueDistributor.addShares(THIRD, shares[2]);
    await abstractValueDistributor.addShares(FOURTH, shares[3]);
  };

  const removeSharesFromAllUsers = async (shares: Array<any>) => {
    await abstractValueDistributor.removeShares(FIRST, shares[0]);
    await abstractValueDistributor.removeShares(SECOND, shares[1]);
    await abstractValueDistributor.removeShares(THIRD, shares[2]);
    await abstractValueDistributor.removeShares(FOURTH, shares[3]);
  };

  const checkAllShares = async (shares: Array<any>) => {
    expect(await abstractValueDistributor.userShares(FIRST)).to.equal(shares[0]);
    expect(await abstractValueDistributor.userShares(SECOND)).to.equal(shares[1]);
    expect(await abstractValueDistributor.userShares(THIRD)).to.equal(shares[2]);
    expect(await abstractValueDistributor.userShares(FOURTH)).to.equal(shares[3]);
  };

  const performSharesManipulations = async () => {
    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractValueDistributor.addShares(FIRST, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractValueDistributor.addShares(SECOND, 200);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractValueDistributor.addShares(THIRD, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractValueDistributor.removeShares(FIRST, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractValueDistributor.addShares(THIRD, 100);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractValueDistributor.removeShares(SECOND, 200);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractValueDistributor.removeShares(THIRD, 200);
  };

  before("setup", async () => {
    [FIRST, SECOND, THIRD, FOURTH] = await ethers.getSigners();

    const abstractValueDistributorMock = await ethers.getContractFactory("AbstractValueDistributorMock");
    abstractValueDistributor = await abstractValueDistributorMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("addShares()", () => {
    it("should add shares correctly", async () => {
      await addSharesToAllUsers([1, 2, 3, 4]);
      await abstractValueDistributor.addShares(FIRST, 5);

      await checkAllShares([6, 2, 3, 4]);
      expect(await abstractValueDistributor.totalShares()).to.equal(15);
    });

    it("should not allow to add 0 shares", async () => {
      await expect(abstractValueDistributor.addShares(SECOND, 0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should trigger the _afterAddShares hook", async () => {
      await expect(abstractValueDistributor.addShares(FIRST, 100))
        .to.emit(abstractValueDistributor, "SharesAdded")
        .withArgs(FIRST.address, 100);
    });
  });

  describe("removeShares()", () => {
    it("should correctly remove shares partially", async () => {
      await addSharesToAllUsers([3, 2, 3, 4]);

      await removeSharesFromAllUsers([1, 1, 1, 2]);
      await abstractValueDistributor.removeShares(THIRD, 1);

      await checkAllShares([2, 1, 1, 2]);
      expect(await abstractValueDistributor.totalShares()).to.equal(6);
    });

    it("should handle removing all the shares correctly", async () => {
      await addSharesToAllUsers([2, 1, 1, 2]);

      await removeSharesFromAllUsers([2, 1, 1, 2]);

      await checkAllShares([0, 0, 0, 0]);
      expect(await abstractValueDistributor.totalShares()).to.equal(0);
    });

    it("should not allow to remove 0 shares", async () => {
      await expect(abstractValueDistributor.removeShares(SECOND, 0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to remove more shares than it was added", async () => {
      await expect(abstractValueDistributor.removeShares(SECOND, 1)).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });

    it("should trigger the _afterRemoveShares hook", async () => {
      await abstractValueDistributor.addShares(FIRST, 100);

      await expect(abstractValueDistributor.removeShares(FIRST, 100))
        .to.emit(abstractValueDistributor, "SharesRemoved")
        .withArgs(FIRST.address, 100);
    });
  });

  describe("distributeValue()", () => {
    it("should calculate the value owed to a user correctly", async () => {
      await abstractValueDistributor.addShares(FIRST, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractValueDistributor.removeShares(FIRST, 100);

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(wei(30));
      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(wei(30));
    });

    it("should calculate the value owed to multiple users correctly", async () => {
      await performSharesManipulations();

      const firstExpectedReward = wei(3) + wei(1) / 12n;
      const secondExpectedReward = wei(3) + wei(1) / 3n;
      const thirdExpectedReward = wei(3) + wei(7) / 12n;

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractValueDistributor.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractValueDistributor.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractValueDistributor.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractValueDistributor.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });

    it("should distribute all the owed values correctly", async () => {
      await performSharesManipulations();

      await abstractValueDistributor.distributeValue(FIRST, await abstractValueDistributor.getOwedValue(FIRST));
      await abstractValueDistributor.distributeValue(SECOND, await abstractValueDistributor.getOwedValue(SECOND));
      await abstractValueDistributor.distributeValue(THIRD, await abstractValueDistributor.getOwedValue(THIRD));

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractValueDistributor.getOwedValue(SECOND)).to.equal(0);
      expect(await abstractValueDistributor.getOwedValue(THIRD)).to.equal(0);

      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(0);
      expect(await abstractValueDistributor.userOwedValue(SECOND)).to.equal(0);
      expect(await abstractValueDistributor.userOwedValue(THIRD)).to.equal(0);
    });

    it("should correctly distribute owed values partially", async () => {
      await performSharesManipulations();

      await abstractValueDistributor.distributeValue(
        FIRST,
        (await abstractValueDistributor.getOwedValue(FIRST)) - wei(1),
      );
      await abstractValueDistributor.distributeValue(
        SECOND,
        (await abstractValueDistributor.getOwedValue(SECOND)) - wei(2),
      );
      await abstractValueDistributor.distributeValue(
        THIRD,
        (await abstractValueDistributor.getOwedValue(THIRD)) - wei(3),
      );

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(wei(1));
      expect(await abstractValueDistributor.getOwedValue(SECOND)).to.equal(wei(2));
      expect(await abstractValueDistributor.getOwedValue(THIRD)).to.equal(wei(3));

      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(wei(1));
      expect(await abstractValueDistributor.userOwedValue(SECOND)).to.equal(wei(2));
      expect(await abstractValueDistributor.userOwedValue(THIRD)).to.equal(wei(3));
    });

    it("should allow to distribute values in several rounds correctly", async () => {
      await performSharesManipulations();

      await abstractValueDistributor.distributeValue(
        FIRST,
        (await abstractValueDistributor.getOwedValue(FIRST)) - wei(3),
      );

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(wei(3));
      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(wei(3));

      await abstractValueDistributor.distributeValue(
        FIRST,
        (await abstractValueDistributor.getOwedValue(FIRST)) - wei(2),
      );

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(wei(2));
      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(wei(2));

      await abstractValueDistributor.distributeValue(FIRST, wei(2));

      expect(await abstractValueDistributor.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractValueDistributor.userOwedValue(FIRST)).to.equal(wei(0));
    });

    it("should not allow to distribute 0 values", async () => {
      await expect(abstractValueDistributor.distributeValue(FIRST, 0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to distribute more values than owed", async () => {
      await performSharesManipulations();

      await expect(abstractValueDistributor.distributeValue(FIRST, wei(4))).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });

    it("should trigger the _afterDistributeValue hook", async () => {
      await abstractValueDistributor.addShares(FIRST, 100);

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractValueDistributor.removeShares(FIRST, 100);

      await expect(abstractValueDistributor.distributeValue(FIRST, 30))
        .to.emit(abstractValueDistributor, "ValueDistributed")
        .withArgs(FIRST.address, 30);
    });
  });
});
