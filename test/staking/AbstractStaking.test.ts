import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { AbstractStakingMock, ERC20Mock } from "@ethers-v6";
import { wei } from "@/scripts/utils/utils";

describe("AbstractStaking", () => {
  const reverter = new Reverter();

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let SHARES_TOKEN: ERC20Mock;
  let REWARDS_TOKEN: ERC20Mock;

  let stakingStartTime: bigint;
  let rate: bigint;

  let abstractStaking: AbstractStakingMock;

  const mintAndApproveTokens = async (user: SignerWithAddress, token: ERC20Mock, amount: number) => {
    await token.mint(user, amount);
    await token.connect(user).approve(abstractStaking, amount);
  };

  const performStakingManipulations = async () => {
    await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);
    await mintAndApproveTokens(SECOND, SHARES_TOKEN, 200);
    await mintAndApproveTokens(THIRD, SHARES_TOKEN, 200);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(FIRST).stake(100);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(SECOND).stake(200);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractStaking.connect(THIRD).stake(100);

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractStaking.connect(FIRST).unstake(100);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractStaking.connect(THIRD).stake(100);

    await time.setNextBlockTimestamp((await time.latest()) + 1);

    await abstractStaking.connect(SECOND).unstake(200);

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(THIRD).unstake(200);
  };

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    abstractStaking = await AbstractStakingMock.deploy();
    SHARES_TOKEN = await ERC20Mock.deploy("SharesMock", "SMock", 18);
    REWARDS_TOKEN = await ERC20Mock.deploy("RewardsMock", "RMock", 18);

    await REWARDS_TOKEN.mint(await abstractStaking.getAddress(), wei(1000));

    stakingStartTime = 3n;
    rate = wei(1);

    await abstractStaking.__AbstractStakingMock_init(SHARES_TOKEN, REWARDS_TOKEN, rate, stakingStartTime);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("AbstractStaking initialization", () => {
    it("should not initialize twice", async () => {
      await expect(abstractStaking.mockInit(SHARES_TOKEN, REWARDS_TOKEN, rate, stakingStartTime)).to.be.revertedWith(
        "Initializable: contract is not initializing",
      );
      await expect(
        abstractStaking.__AbstractStakingMock_init(SHARES_TOKEN, REWARDS_TOKEN, rate, stakingStartTime),
      ).to.be.revertedWith("Initializable: contract is already initialized");
    });

    it("should set the initial values correctly", async () => {
      expect(await abstractStaking.sharesToken()).to.equal(await SHARES_TOKEN.getAddress());
      expect(await abstractStaking.rewardsToken()).to.equal(await REWARDS_TOKEN.getAddress());
      expect(await abstractStaking.rate()).to.equal(rate);
      expect(await abstractStaking.stakingStartTime()).to.equal(stakingStartTime);
    });
  });

  describe("stakingStartTime", () => {
    it("should not allow to stake, unstake, withdraw tokens or claim rewards before the start of the staking", async () => {
      await abstractStaking.setStakingStartTime(1638474321);

      const revertMessage = "Staking: staking has not started yet";

      await expect(abstractStaking.stake(100)).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.unstake(100)).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.withdraw()).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.claim(100)).to.be.revertedWith(revertMessage);
    });
  });

  describe("stake()", () => {
    it("should add shares after staking correctly", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);
      await mintAndApproveTokens(SECOND, SHARES_TOKEN, 300);

      await abstractStaking.connect(FIRST).stake(100);
      await abstractStaking.connect(SECOND).stake(300);

      expect(await abstractStaking.totalShares()).to.equal(400);
      expect(await abstractStaking.userShares(FIRST)).to.equal(100);
      expect(await abstractStaking.userShares(SECOND)).to.equal(300);
    });

    it("should transfer tokens corrently on stake", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await expect(abstractStaking.connect(FIRST).stake(50))
        .to.emit(SHARES_TOKEN, "Transfer")
        .withArgs(FIRST.address, await abstractStaking.getAddress(), 50);

      expect(await SHARES_TOKEN.balanceOf(FIRST)).to.equal(50);
      expect(await SHARES_TOKEN.balanceOf(abstractStaking)).to.equal(50);

      await abstractStaking.connect(FIRST).stake(50);

      expect(await SHARES_TOKEN.balanceOf(FIRST)).to.equal(0);
      expect(await SHARES_TOKEN.balanceOf(abstractStaking)).to.equal(100);
    });

    it("should not allow to stake 0 tokens", async () => {
      await expect(abstractStaking.connect(FIRST).stake(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });
  });

  describe("unstake()", () => {
    it("should remove shares after unstaking correctly", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);
      await mintAndApproveTokens(SECOND, SHARES_TOKEN, 300);

      await abstractStaking.connect(FIRST).stake(100);
      await abstractStaking.connect(SECOND).stake(300);

      await abstractStaking.connect(FIRST).unstake(50);
      await abstractStaking.connect(SECOND).unstake(200);

      expect(await abstractStaking.totalShares()).to.equal(150);
      expect(await abstractStaking.userShares(FIRST)).to.equal(50);
      expect(await abstractStaking.userShares(SECOND)).to.equal(100);
    });

    it("should handle unstaking the whole amount staked correctly", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);
      await abstractStaking.connect(FIRST).unstake(100);

      expect(await abstractStaking.totalShares()).to.equal(0);
      expect(await abstractStaking.userShares(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on unstake", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);

      await expect(abstractStaking.connect(FIRST).unstake(50))
        .to.emit(SHARES_TOKEN, "Transfer")
        .withArgs(await abstractStaking.getAddress(), FIRST.address, 50);

      expect(await SHARES_TOKEN.balanceOf(FIRST)).to.equal(50);
      expect(await SHARES_TOKEN.balanceOf(abstractStaking)).to.equal(50);

      await abstractStaking.connect(FIRST).unstake(50);

      expect(await SHARES_TOKEN.balanceOf(FIRST)).to.equal(100);
      expect(await SHARES_TOKEN.balanceOf(abstractStaking)).to.equal(0);
    });

    it("should not allow to unstake 0 tokens", async () => {
      await expect(abstractStaking.connect(FIRST).unstake(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to unstake more than it was staked", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);
      await expect(abstractStaking.connect(FIRST).unstake(150)).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });
  });

  describe("withdraw()", () => {
    it("should withdraw tokens correctly", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);

      await abstractStaking.connect(FIRST).withdraw();

      expect(await abstractStaking.totalShares()).to.equal(0);
      expect(await abstractStaking.userShares(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on withdraw", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);

      await expect(abstractStaking.connect(FIRST).withdraw())
        .to.emit(SHARES_TOKEN, "Transfer")
        .withArgs(await abstractStaking.getAddress(), FIRST.address, 100);

      expect(await SHARES_TOKEN.balanceOf(abstractStaking)).to.equal(0);
      expect(await SHARES_TOKEN.balanceOf(FIRST)).to.equal(100);
    });

    it("should claim all the rewards earned after the withdrawal", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractStaking.connect(FIRST).withdraw();

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(0));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(0));
    });
  });

  describe("claim()", () => {
    it("should calculate the rewards earned for a user correctly", async () => {
      await mintAndApproveTokens(FIRST, SHARES_TOKEN, 100);

      await abstractStaking.connect(FIRST).stake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractStaking.connect(FIRST).unstake(100);

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(30));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(30));
    });

    it("should calculate the reward earned for multiple users correctly", async () => {
      await performStakingManipulations();

      const firstExpectedReward = wei(3) + wei(1) / 12n;
      const secondExpectedReward = wei(3) + wei(1) / 3n;
      const thirdExpectedReward = wei(3) + wei(7) / 12n;

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractStaking.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractStaking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractStaking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });

    it("should claim all the rewards correctly", async () => {
      await performStakingManipulations();

      await abstractStaking.connect(FIRST).claim(await abstractStaking.getOwedValue(FIRST));
      await abstractStaking.connect(SECOND).claim(await abstractStaking.getOwedValue(SECOND));
      await abstractStaking.connect(THIRD).claim(await abstractStaking.getOwedValue(THIRD));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.getOwedValue(SECOND)).to.equal(0);
      expect(await abstractStaking.getOwedValue(THIRD)).to.equal(0);

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(0);
      expect(await abstractStaking.userOwedValue(THIRD)).to.equal(0);
    });

    it("should correctly claim rewards partially", async () => {
      await performStakingManipulations();

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(1));
      await abstractStaking.connect(SECOND).claim((await abstractStaking.getOwedValue(SECOND)) - wei(2));
      await abstractStaking.connect(THIRD).claim((await abstractStaking.getOwedValue(THIRD)) - wei(3));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(1));
      expect(await abstractStaking.getOwedValue(SECOND)).to.equal(wei(2));
      expect(await abstractStaking.getOwedValue(THIRD)).to.equal(wei(3));

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(1));
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(wei(2));
      expect(await abstractStaking.userOwedValue(THIRD)).to.equal(wei(3));
    });

    it("should allow to claim rewards in several rounds correctly", async () => {
      await performStakingManipulations();

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(3));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(3));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(3));

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(2));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(2));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(2));

      await abstractStaking.connect(FIRST).claim(wei(2));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(0));
    });

    it("should transfer tokens correctly on the claim", async () => {
      await performStakingManipulations();

      const initialRewardsBalance = await REWARDS_TOKEN.balanceOf(abstractStaking);

      const firstOwed = await abstractStaking.getOwedValue(FIRST);
      const secondOwed = await abstractStaking.getOwedValue(SECOND);
      const thirdOwed = await abstractStaking.getOwedValue(THIRD);

      await abstractStaking.connect(FIRST).claim(firstOwed);
      await abstractStaking.connect(SECOND).claim(secondOwed);

      await expect(abstractStaking.connect(THIRD).claim(thirdOwed))
        .to.emit(REWARDS_TOKEN, "Transfer")
        .withArgs(await abstractStaking.getAddress(), THIRD.address, thirdOwed);

      expect(await REWARDS_TOKEN.balanceOf(abstractStaking)).to.equal(
        initialRewardsBalance - (firstOwed + secondOwed + thirdOwed),
      );
      expect(await REWARDS_TOKEN.balanceOf(FIRST)).to.equal(firstOwed);
      expect(await REWARDS_TOKEN.balanceOf(SECOND)).to.equal(secondOwed);
      expect(await REWARDS_TOKEN.balanceOf(THIRD)).to.equal(thirdOwed);
    });

    it("should not allow to claim 0 rewards", async () => {
      await expect(abstractStaking.connect(FIRST).claim(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to claim more rewards than earned", async () => {
      await performStakingManipulations();

      await expect(abstractStaking.connect(FIRST).claim(wei(4))).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });
  });

  describe("should handle staking manipulations with 6-decimal values", () => {
    it("should handle the whole staling process using 6-decimal values", async () => {
      const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const abstractStaking6Decimals = await AbstractStakingMock.deploy();
      const SHARES_TOKEN = await ERC20Mock.deploy("SharesMock", "SMock", 6);
      const REWARDS_TOKEN = await ERC20Mock.deploy("RewardsMock", "RMock", 6);
      await REWARDS_TOKEN.mint(await abstractStaking6Decimals.getAddress(), wei(1000));

      await abstractStaking6Decimals.__AbstractStakingMock_init(SHARES_TOKEN, REWARDS_TOKEN, wei(1, 6), 3n);

      await SHARES_TOKEN.mint(FIRST, 100);
      await SHARES_TOKEN.mint(SECOND, 200);
      await SHARES_TOKEN.mint(THIRD, 200);
      await REWARDS_TOKEN.mint(await abstractStaking6Decimals.getAddress(), wei(1000));

      await SHARES_TOKEN.connect(FIRST).approve(abstractStaking6Decimals.getAddress(), 100);
      await SHARES_TOKEN.connect(SECOND).approve(abstractStaking6Decimals.getAddress(), 200);
      await SHARES_TOKEN.connect(THIRD).approve(abstractStaking6Decimals.getAddress(), 200);

      await time.setNextBlockTimestamp((await time.latest()) + 2);

      await abstractStaking6Decimals.connect(FIRST).stake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 2);

      await abstractStaking6Decimals.connect(SECOND).stake(200);

      await time.setNextBlockTimestamp((await time.latest()) + 1);

      await abstractStaking6Decimals.connect(THIRD).stake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await abstractStaking6Decimals.connect(FIRST).unstake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 1);

      await abstractStaking6Decimals.connect(THIRD).stake(100);

      await time.setNextBlockTimestamp((await time.latest()) + 1);

      await abstractStaking6Decimals.connect(SECOND).unstake(200);

      await time.setNextBlockTimestamp((await time.latest()) + 2);

      await abstractStaking6Decimals.connect(THIRD).unstake(200);

      const firstExpectedReward = wei(3, 6) + wei(1, 6) / 12n;
      const secondExpectedReward = wei(3, 6) + wei(1, 6) / 3n;
      const thirdExpectedReward = wei(3, 6) + wei(7, 6) / 12n;

      expect(await abstractStaking6Decimals.getOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractStaking6Decimals.getOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractStaking6Decimals.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await abstractStaking6Decimals.userOwedValue(FIRST)).to.equal(firstExpectedReward);
      expect(await abstractStaking6Decimals.userOwedValue(SECOND)).to.equal(secondExpectedReward);
      expect(await abstractStaking6Decimals.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });
  });
});
