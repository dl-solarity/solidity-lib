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

  let sharesToken: ERC20Mock;
  let rewardsToken: ERC20Mock;

  let sharesDecimals: number;
  let rewardsDecimals: number;

  let stakingStartTime: bigint;
  let rate: bigint;

  let abstractStaking: AbstractStakingMock;

  const mintAndApproveTokens = async (user: SignerWithAddress, token: ERC20Mock, amount: bigint) => {
    await token.mint(user, amount);
    await token.connect(user).approve(abstractStaking, amount);
  };

  const performStakingManipulations = async () => {
    await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
    await mintAndApproveTokens(SECOND, sharesToken, wei(200, sharesDecimals));
    await mintAndApproveTokens(THIRD, sharesToken, wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(SECOND).stake(wei(200, sharesDecimals));

    await abstractStaking.connect(THIRD).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractStaking.connect(FIRST).unstake(wei(100, sharesDecimals));

    await abstractStaking.connect(THIRD).stake(wei(100, sharesDecimals));

    await abstractStaking.connect(SECOND).unstake(wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(THIRD).unstake(wei(200, sharesDecimals));
  };

  const checkManipulationRewards = async () => {
    const firstExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 12n;
    const secondExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 3n;
    const thirdExpectedReward = wei(3, rewardsDecimals) + wei(7, rewardsDecimals) / 12n;

    expect(await abstractStaking.getOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await abstractStaking.getOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await abstractStaking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

    expect(await abstractStaking.userOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await abstractStaking.userOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await abstractStaking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
  };

  const performStakingManipulations2 = async () => {
    await mintAndApproveTokens(FIRST, sharesToken, wei(400, sharesDecimals));
    await mintAndApproveTokens(SECOND, sharesToken, wei(100, sharesDecimals));
    await mintAndApproveTokens(THIRD, sharesToken, wei(400, sharesDecimals));

    await abstractStaking.connect(FIRST).stake(wei(200, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractStaking.connect(SECOND).stake(wei(100, sharesDecimals));

    await abstractStaking.connect(THIRD).stake(wei(300, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractStaking.connect(FIRST).stake(wei(200, sharesDecimals));

    await abstractStaking.connect(FIRST).unstake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 3);

    await abstractStaking.connect(SECOND).unstake(wei(100, sharesDecimals));

    await abstractStaking.connect(THIRD).stake(wei(100, sharesDecimals));

    await time.setNextBlockTimestamp((await time.latest()) + 2);

    await abstractStaking.connect(FIRST).unstake(wei(300, sharesDecimals));

    await abstractStaking.connect(THIRD).unstake(wei(400, sharesDecimals));
  };

  const checkManipulationRewards2 = async () => {
    const firstExpectedReward = wei(7, rewardsDecimals) + wei(2, rewardsDecimals) / 3n + wei(1, rewardsDecimals) / 7n;
    const secondExpectedReward = wei(233, rewardsDecimals) / 168n;
    const thirdExpectedReward = wei(5, rewardsDecimals) + wei(3, rewardsDecimals) / 8n + wei(3, rewardsDecimals) / 7n;

    expect(await abstractStaking.getOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await abstractStaking.getOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await abstractStaking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

    expect(await abstractStaking.userOwedValue(FIRST)).to.equal(firstExpectedReward);
    expect(await abstractStaking.userOwedValue(SECOND)).to.equal(secondExpectedReward);
    expect(await abstractStaking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
  };

  before("setup", async () => {
    [FIRST, SECOND, THIRD] = await ethers.getSigners();

    const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    abstractStaking = await AbstractStakingMock.deploy();
    sharesToken = await ERC20Mock.deploy("SharesMock", "SMock", 18);
    rewardsToken = await ERC20Mock.deploy("RewardsMock", "RMock", 18);

    sharesDecimals = Number(await sharesToken.decimals());
    rewardsDecimals = Number(await rewardsToken.decimals());

    await rewardsToken.mint(await abstractStaking.getAddress(), wei(100, rewardsDecimals));

    stakingStartTime = 3n;
    rate = wei(1, rewardsDecimals);

    await abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("AbstractStaking initialization", () => {
    it("should not initialize twice", async () => {
      await expect(abstractStaking.mockInit(sharesToken, rewardsToken, rate, stakingStartTime)).to.be.revertedWith(
        "Initializable: contract is not initializing",
      );
      await expect(
        abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime),
      ).to.be.revertedWith("Initializable: contract is already initialized");
    });

    it("should set the initial values correctly", async () => {
      expect(await abstractStaking.sharesToken()).to.equal(await sharesToken.getAddress());
      expect(await abstractStaking.rewardsToken()).to.equal(await rewardsToken.getAddress());
      expect(await abstractStaking.rate()).to.equal(rate);
      expect(await abstractStaking.stakingStartTime()).to.equal(stakingStartTime);
    });
  });

  describe("timestamps", () => {
    it("should not allow to stake, unstake, withdraw tokens or claim rewards before the start of the staking", async () => {
      await abstractStaking.setStakingStartTime(1638474321);

      const revertMessage = "Staking: staking has not started yet";

      await expect(abstractStaking.stake(wei(100, sharesDecimals))).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.unstake(wei(100, sharesDecimals))).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.withdraw()).to.be.revertedWith(revertMessage);
      await expect(abstractStaking.claim(wei(100, sharesDecimals))).to.be.revertedWith(revertMessage);
    });

    it("should work as expected if the staking start time is set to the timestamp in the past", async () => {
      await time.setNextBlockTimestamp((await time.latest()) + 20);

      await abstractStaking.setStakingStartTime(2);

      expect(await abstractStaking.stakingStartTime()).to.equal(2);

      await performStakingManipulations();

      await checkManipulationRewards();
    });

    it("should update values correctly if more than one transaction which updates the key values is sent within one block", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(400, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));
      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await abstractStaking.multicall([
        abstractStaking.interface.encodeFunctionData("stake", [wei(100, sharesDecimals)]),
        abstractStaking.interface.encodeFunctionData("stake", [wei(100, sharesDecimals)]),
      ]);

      expect(await abstractStaking.userShares(FIRST)).to.equal(wei(400, sharesDecimals));
      expect(await abstractStaking.cumulativeSum()).to.equal(wei(1.5, 23));
    });

    it("should work as expected if more than one transaction which updates the key values is sent within one block", async () => {
      const StakersFactory = await ethers.getContractFactory("StakersFactory");
      const stakersFactory = await StakersFactory.deploy();

      await stakersFactory.createStaker();
      await stakersFactory.createStaker();

      const staker1 = await stakersFactory.stakers(0);
      const staker2 = await stakersFactory.stakers(1);

      await sharesToken.mint(staker1, wei(500, sharesDecimals));
      await sharesToken.mint(staker2, wei(500, sharesDecimals));
      await mintAndApproveTokens(THIRD, sharesToken, wei(100, sharesDecimals));

      await stakersFactory.stake(abstractStaking, staker1, sharesToken, wei(100, sharesDecimals));

      await stakersFactory.multicall([
        stakersFactory.interface.encodeFunctionData("stake", [
          await abstractStaking.getAddress(),
          staker1,
          await sharesToken.getAddress(),
          wei(200, sharesDecimals),
        ]),
        stakersFactory.interface.encodeFunctionData("stake", [
          await abstractStaking.getAddress(),
          staker2,
          await sharesToken.getAddress(),
          wei(200, sharesDecimals),
        ]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await stakersFactory.unstake(abstractStaking, staker2, wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 4);

      await abstractStaking.connect(THIRD).stake(wei(100, sharesDecimals));

      await stakersFactory.multicall([
        stakersFactory.interface.encodeFunctionData("unstake", [
          await abstractStaking.getAddress(),
          staker1,
          wei(300, sharesDecimals),
        ]),
        stakersFactory.interface.encodeFunctionData("unstake", [
          await abstractStaking.getAddress(),
          staker2,
          wei(100, sharesDecimals),
        ]),
      ]);

      await time.setNextBlockTimestamp((await time.latest()) + 3);

      await abstractStaking.connect(THIRD).unstake(wei(100, sharesDecimals));

      const firstExpectedReward = wei(6, rewardsDecimals) + wei(2, rewardsDecimals) / 5n;
      const secondExpectedReward = wei(2, rewardsDecimals) + wei(2, rewardsDecimals) / 5n;
      const thirdExpectedReward = wei(3, rewardsDecimals) + wei(1, rewardsDecimals) / 5n;

      expect(await abstractStaking.getOwedValue(staker1)).to.equal(firstExpectedReward);
      expect(await abstractStaking.getOwedValue(staker2)).to.equal(secondExpectedReward);
      expect(await abstractStaking.getOwedValue(THIRD)).to.equal(thirdExpectedReward);

      expect(await abstractStaking.userOwedValue(staker1)).to.equal(firstExpectedReward);
      expect(await abstractStaking.userOwedValue(staker2)).to.equal(secondExpectedReward);
      expect(await abstractStaking.userOwedValue(THIRD)).to.equal(thirdExpectedReward);
    });
  });

  describe("stake()", () => {
    it("should add shares after staking correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));
      await abstractStaking.connect(SECOND).stake(wei(300, sharesDecimals));

      expect(await abstractStaking.totalShares()).to.equal(wei(400, sharesDecimals));
      expect(await abstractStaking.userShares(FIRST)).to.equal(wei(100, sharesDecimals));
      expect(await abstractStaking.userShares(SECOND)).to.equal(wei(300, sharesDecimals));
    });

    it("should transfer tokens correctly on stake", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await sharesToken.balanceOf(abstractStaking)).to.equal(wei(50, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(0);
      expect(await sharesToken.balanceOf(abstractStaking)).to.equal(wei(100, sharesDecimals));
    });

    it("should not allow to stake 0 tokens", async () => {
      await expect(abstractStaking.connect(FIRST).stake(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });
  });

  describe("unstake()", () => {
    it("should remove shares after unstaking correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));
      await abstractStaking.connect(SECOND).stake(wei(300, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await abstractStaking.connect(SECOND).unstake(wei(200, sharesDecimals));

      expect(await abstractStaking.totalShares()).to.equal(wei(150, sharesDecimals));
      expect(await abstractStaking.userShares(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await abstractStaking.userShares(SECOND)).to.equal(wei(100, sharesDecimals));
    });

    it("should handle unstaking the whole amount staked correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(200, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));
      await abstractStaking.connect(SECOND).stake(wei(200, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(100, sharesDecimals));
      await abstractStaking.connect(SECOND).unstake(wei(200, sharesDecimals));

      const cumulativeSum = await abstractStaking.cumulativeSum();

      expect(await abstractStaking.totalShares()).to.equal(0);
      expect(await abstractStaking.userShares(FIRST)).to.equal(0);
      expect(await abstractStaking.userShares(SECOND)).to.equal(0);

      await sharesToken.connect(FIRST).approve(abstractStaking, wei(50, sharesDecimals));
      await sharesToken.connect(SECOND).approve(abstractStaking, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(50, sharesDecimals));

      expect(await abstractStaking.cumulativeSum()).to.equal(cumulativeSum);

      await abstractStaking.connect(SECOND).stake(wei(100, sharesDecimals));

      expect(await abstractStaking.totalShares()).to.equal(wei(150, sharesDecimals));
      expect(await abstractStaking.userShares(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await abstractStaking.userShares(SECOND)).to.equal(wei(100, sharesDecimals));
    });

    it("should transfer tokens correctly on unstake", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(50, sharesDecimals));
      expect(await sharesToken.balanceOf(abstractStaking)).to.equal(wei(50, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(50, sharesDecimals));

      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(100, sharesDecimals));
      expect(await sharesToken.balanceOf(abstractStaking)).to.equal(0);
    });

    it("should not allow to unstake 0 tokens", async () => {
      await expect(abstractStaking.connect(FIRST).unstake(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to unstake more than it was staked", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));
      await expect(abstractStaking.connect(FIRST).unstake(wei(150, sharesDecimals))).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });
  });

  describe("withdraw()", () => {
    it("should withdraw tokens correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).withdraw();

      expect(await abstractStaking.totalShares()).to.equal(0);
      expect(await abstractStaking.userShares(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on withdraw", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).withdraw();

      expect(await sharesToken.balanceOf(abstractStaking)).to.equal(0);
      expect(await sharesToken.balanceOf(FIRST)).to.equal(wei(100, sharesDecimals));
    });

    it("should claim all the rewards earned after the withdrawal", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractStaking.connect(FIRST).withdraw();

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(0);
    });
  });

  describe("claim()", () => {
    it("should calculate the rewards earned for a user correctly", async () => {
      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 30);

      await abstractStaking.connect(FIRST).unstake(wei(100, sharesDecimals));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(30, rewardsDecimals));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(30, rewardsDecimals));
    });

    it("should calculate the reward earned for multiple users correctly", async () => {
      await performStakingManipulations();

      await checkManipulationRewards();
    });

    it("should calculate the reward earned for multiple users correctly", async () => {
      await performStakingManipulations2();

      await checkManipulationRewards2();
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

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(1, rewardsDecimals));
      await abstractStaking
        .connect(SECOND)
        .claim((await abstractStaking.getOwedValue(SECOND)) - wei(2, rewardsDecimals));
      await abstractStaking.connect(THIRD).claim((await abstractStaking.getOwedValue(THIRD)) - wei(3, rewardsDecimals));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(1, rewardsDecimals));
      expect(await abstractStaking.getOwedValue(SECOND)).to.equal(wei(2, rewardsDecimals));
      expect(await abstractStaking.getOwedValue(THIRD)).to.equal(wei(3, rewardsDecimals));

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(1, rewardsDecimals));
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(wei(2, rewardsDecimals));
      expect(await abstractStaking.userOwedValue(THIRD)).to.equal(wei(3, rewardsDecimals));
    });

    it("should allow to claim rewards in several rounds correctly", async () => {
      await performStakingManipulations2();

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(3));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(3, rewardsDecimals));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(3, rewardsDecimals));

      await abstractStaking.connect(FIRST).claim((await abstractStaking.getOwedValue(FIRST)) - wei(2));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(wei(2, rewardsDecimals));
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(wei(2, rewardsDecimals));

      await abstractStaking.connect(FIRST).claim(wei(2, rewardsDecimals));

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(0);
    });

    it("should transfer tokens correctly on the claim", async () => {
      await performStakingManipulations();

      const initialRewardsBalance = await rewardsToken.balanceOf(abstractStaking);

      const firstOwed = await abstractStaking.getOwedValue(FIRST);
      const secondOwed = await abstractStaking.getOwedValue(SECOND);
      const thirdOwed = await abstractStaking.getOwedValue(THIRD);

      await abstractStaking.connect(FIRST).claim(firstOwed);
      await abstractStaking.connect(SECOND).claim(secondOwed);

      await abstractStaking.connect(THIRD).claim(thirdOwed);

      expect(await rewardsToken.balanceOf(abstractStaking)).to.equal(
        initialRewardsBalance - (firstOwed + secondOwed + thirdOwed),
      );
      expect(await rewardsToken.balanceOf(FIRST)).to.equal(firstOwed);
      expect(await rewardsToken.balanceOf(SECOND)).to.equal(secondOwed);
      expect(await rewardsToken.balanceOf(THIRD)).to.equal(thirdOwed);
    });

    it("should not allow to claim 0 rewards", async () => {
      await expect(abstractStaking.connect(FIRST).claim(0)).to.be.revertedWith(
        "ValueDistributor: amount has to be more than 0",
      );
    });

    it("should not allow to claim more rewards than earned", async () => {
      await performStakingManipulations();

      await expect(abstractStaking.connect(FIRST).claim(wei(4, rewardsDecimals))).to.be.revertedWith(
        "ValueDistributor: insufficient amount",
      );
    });
  });

  describe("rate", () => {
    it("should accept 0 as a rate and calculate owed values according to this rate correctly", async () => {
      const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
      abstractStaking = await AbstractStakingMock.deploy();

      await abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, 0, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(100, sharesDecimals));

      await time.setNextBlockTimestamp((await time.latest()) + 20);

      await abstractStaking.connect(FIRST).unstake(wei(100, sharesDecimals));

      expect(await abstractStaking.rate()).to.equal(0);

      expect(await abstractStaking.getOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(0);
      expect(await abstractStaking.cumulativeSum()).to.equal(0);
    });

    it("should calculate owed value properly after the rate is changed to 0", async () => {
      const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
      abstractStaking = await AbstractStakingMock.deploy();

      await abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(50, sharesDecimals));
      await abstractStaking.connect(SECOND).stake(wei(150, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await abstractStaking.connect(SECOND).unstake(wei(100, sharesDecimals));

      await abstractStaking.setRate(0);

      expect(await abstractStaking.rate()).to.equal(0);

      await abstractStaking.connect(SECOND).unstake(wei(50, sharesDecimals));

      let firstOwedValue = await abstractStaking.getOwedValue(FIRST);
      let secondOwedValue = await abstractStaking.getOwedValue(SECOND);

      await performStakingManipulations();

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(firstOwedValue);
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(secondOwedValue);
    });

    it("should work as expected after updating the rate", async () => {
      const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
      abstractStaking = await AbstractStakingMock.deploy();

      await abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, rate, stakingStartTime);

      await mintAndApproveTokens(FIRST, sharesToken, wei(100, sharesDecimals));
      await mintAndApproveTokens(SECOND, sharesToken, wei(300, sharesDecimals));

      await abstractStaking.connect(FIRST).stake(wei(50, sharesDecimals));
      await abstractStaking.connect(SECOND).stake(wei(150, sharesDecimals));

      await abstractStaking.connect(FIRST).unstake(wei(50, sharesDecimals));
      await abstractStaking.connect(SECOND).unstake(wei(100, sharesDecimals));

      const prevCumulativeSum = await abstractStaking.cumulativeSum();

      let firstOwedValue = await abstractStaking.getOwedValue(FIRST);
      let secondOwedValue = await abstractStaking.getOwedValue(SECOND);

      await abstractStaking.setRate(wei(2, rewardsDecimals));

      const expectedCumulativeSum = prevCumulativeSum + wei(rate, 25) / (await abstractStaking.totalShares());

      expect(await abstractStaking.rate()).to.equal(wei(2, rewardsDecimals));
      expect(await abstractStaking.cumulativeSum()).to.equal(expectedCumulativeSum);
      expect(await abstractStaking.updatedAt()).to.equal(await time.latest());

      expect(await abstractStaking.userOwedValue(FIRST)).to.equal(firstOwedValue);
      expect(await abstractStaking.userOwedValue(SECOND)).to.equal(secondOwedValue);
    });
  });

  describe("should handle staking manipulations with 6-decimal values", () => {
    it("should handle the whole staling process using 6-decimal values", async () => {
      const AbstractStakingMock = await ethers.getContractFactory("AbstractStakingMock");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      abstractStaking = await AbstractStakingMock.deploy();
      sharesToken = await ERC20Mock.deploy("SharesMock", "SMock", 6);
      rewardsToken = await ERC20Mock.deploy("RewardsMock", "RMock", 6);

      sharesDecimals = Number(await sharesToken.decimals());
      rewardsDecimals = Number(await rewardsToken.decimals());

      await rewardsToken.mint(await abstractStaking.getAddress(), wei(100, rewardsDecimals));

      await abstractStaking.__AbstractStakingMock_init(sharesToken, rewardsToken, wei(1, rewardsDecimals), 3n);

      await performStakingManipulations2();

      await checkManipulationRewards2();
    });
  });
});
