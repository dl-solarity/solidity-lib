import { MAX_UINT256, ZERO_ADDR } from "@/scripts/utils/constants";
import { precision, wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { ERC20Mock, ERC20Mock__factory, Vesting, VestingMock, VestingMock__factory } from "@ethers-v6";

describe.only("Vesting", () => {
  let reverter = new Reverter();

  let owner: SignerWithAddress;
  let alice: SignerWithAddress;

  let vesting: VestingMock;
  let erc20: ERC20Mock;

  type BaseSchedule = Vesting.BaseScheduleStruct;
  type Schedule = Vesting.ScheduleStruct;
  type Vesting = Vesting.VestingDataStruct;

  const LINEAR_EXPONENT = 1n;

  const secondsInPeriod = 60n * 60n * 24n; // one day;
  const durationInPeriods = 30n; // days
  const cliffInPeriods = 1n;
  const vestingAmount = wei(100_000);
  const exponent = 4n;

  before(async () => {
    [owner, alice] = await ethers.getSigners();

    vesting = await new VestingMock__factory(owner).deploy();
    erc20 = await new ERC20Mock__factory(owner).deploy("Test", "TST", 18);

    await vesting.__VestingMock_init();

    await erc20.mint(owner.address, wei(1_000_000));
    await erc20.approve(await vesting.getAddress(), MAX_UINT256);

    reverter.snapshot();
  });

  afterEach(reverter.revert);

  async function calculateVestedAmount(vestingStartTime: bigint, vestingAmount: bigint, exponent: bigint) {
    let elapsedPeriods = (BigInt(await time.latest()) - vestingStartTime) / secondsInPeriod;
    let elapsedPeriodsPercentage = (elapsedPeriods * precision(1)) / durationInPeriods;
    let vestedAmount = (elapsedPeriodsPercentage ** exponent * vestingAmount) / precision(1) ** exponent;

    return vestedAmount;
  }

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(vesting.__VestingMock_init()).to.be.revertedWith("Initializable: contract is already initialized");
      await expect(vesting.vestingInit()).to.be.revertedWith("Initializable: contract is not initializing");
    });
  });
  describe("create schedule", () => {
    it("should correctly create linear schedule", async () => {
      let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;

      const tx = vesting.createBaseSchedule(baseSchedule);

      await expect(tx).to.emit(vesting, "ScheduleCreated").withArgs(1);

      expect(await vesting.scheduleId()).to.equal(1);
      expect(await vesting.getSchedule(1)).to.deep.equal([Object.values(baseSchedule), LINEAR_EXPONENT]);
    });

    it("should correctly create exponential schedule", async () => {
      let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
      let schedule = { scheduleData: baseSchedule, exponent: exponent } as Schedule;

      const tx = vesting.createSchedule(schedule);

      await expect(tx).to.emit(vesting, "ScheduleCreated").withArgs(1);

      expect(await vesting.scheduleId()).to.equal(1);
      expect(await vesting.getSchedule(1)).to.deep.equal([Object.values(baseSchedule), exponent]);
    });

    it("should revert if duration periods is 0", async () => {
      let baseSchedule = { secondsInPeriod, durationInPeriods: 0, cliffInPeriods } as BaseSchedule;

      await expect(vesting.createBaseSchedule(baseSchedule)).to.be.revertedWith(
        "VestingWallet: cannot create schedule with zero duration or zero seconds in period",
      );
    });

    it("should revert if seconds in period is 0", async () => {
      let baseSchedule = { secondsInPeriod: 0, durationInPeriods, cliffInPeriods } as BaseSchedule;

      await expect(vesting.createBaseSchedule(baseSchedule)).to.be.revertedWith(
        "VestingWallet: cannot create schedule with zero duration or zero seconds in period",
      );
    });

    it("should revert if cliff is greater than duration", async () => {
      let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods: durationInPeriods + 1n } as BaseSchedule;

      await expect(vesting.createBaseSchedule(baseSchedule)).to.be.revertedWith(
        "VestingWallet: cliff cannot be greater than duration",
      );
    });

    it("should revert if exponent is 0", async () => {
      let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
      let schedule = { scheduleData: baseSchedule, exponent: 0 } as Schedule;

      await expect(vesting.createSchedule(schedule)).to.be.revertedWith(
        "VestingWallet: cannot create schedule with zero exponent",
      );
    });
  });
  describe("create vesting", () => {
    let linearSchedule: BaseSchedule;
    let linearScheduleId: bigint;
    let exponentialSchedule: Schedule;
    let exponentialScheduleId: bigint;

    let defaultVesting: Vesting;

    beforeEach(async () => {
      linearSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
      exponentialSchedule = { scheduleData: linearSchedule, exponent: exponent } as Schedule;

      let tx = await vesting.createBaseSchedule(linearSchedule);
      linearScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);

      tx = await vesting.createSchedule(exponentialSchedule);
      exponentialScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);

      defaultVesting = {
        vestingStartTime: await time.latest(),
        beneficiary: alice.address,
        vestingToken: await erc20.getAddress(),
        vestingAmount: vestingAmount,
        paidAmount: 0,
        scheduleId: linearScheduleId,
      } as Vesting;
    });

    it("should correctly create vesting", async () => {
      let linearVesting = {
        vestingStartTime: await time.latest(),
        beneficiary: alice.address,
        vestingToken: await erc20.getAddress(),
        vestingAmount: vestingAmount,
        paidAmount: 0,
        scheduleId: linearScheduleId,
      } as Vesting;

      let exponentialVesting = {
        ...linearVesting,
        scheduleId: exponentialScheduleId,
        vestingAmount: vestingAmount * 2n,
      };

      const linearTx = vesting.createVesting(linearVesting);
      const exponentialTx = vesting.createVesting(exponentialVesting);

      await expect(linearTx)
        .to.emit(vesting, "VestingCreated")
        .withArgs(1, linearVesting.beneficiary, linearVesting.vestingToken);

      await expect(exponentialTx)
        .to.emit(vesting, "VestingCreated")
        .withArgs(2, exponentialVesting.beneficiary, exponentialVesting.vestingToken);

      expect(await vesting.vestingId()).to.equal(2);
      expect(await vesting.getVesting(1)).to.deep.equal(Object.values(linearVesting));
      expect(await vesting.getVesting(2)).to.deep.equal(Object.values(exponentialVesting));

      expect(await vesting.getVestingIds(await alice.getAddress())).to.deep.equal([1, 2]);
      expect(await vesting.getVestings(await alice.getAddress())).to.deep.equal([
        Object.values(linearVesting),
        Object.values(exponentialVesting),
      ]);

      expect(await erc20.balanceOf(await vesting.getAddress())).changeTokenBalance(
        erc20,
        await vesting.getAddress(),
        vestingAmount * 2n,
      );
    });

    it("should revert if vesting start time is zero", async () => {
      defaultVesting.vestingStartTime = 0;

      await expect(vesting.createVesting(defaultVesting)).to.be.revertedWith(
        "VestingWallet: cannot create vesting for zero time",
      );
    });

    it("should revert if vesting amount is zero", async () => {
      defaultVesting.vestingAmount = 0;

      await expect(vesting.createVesting(defaultVesting)).to.be.revertedWith(
        "VestingWallet: cannot create vesting for zero amount",
      );
    });

    it("should revert if vesting beneficiary is zero address", async () => {
      defaultVesting.beneficiary = ZERO_ADDR;

      await expect(vesting.createVesting(defaultVesting)).to.be.revertedWith(
        "VestingWallet: cannot create vesting for zero address",
      );
    });

    it("should revert if vesting token is zero address", async () => {
      defaultVesting.vestingToken = ZERO_ADDR;

      await expect(vesting.createVesting(defaultVesting)).to.be.revertedWith(
        "VestingWallet: vesting token cannot be zero address",
      );
    });

    it("should revert if vesting created for a past date", async () => {
      await time.increase(secondsInPeriod * durationInPeriods);

      await expect(vesting.createVesting(defaultVesting)).to.be.revertedWith(
        "VestingWallet: cannot create vesting for a past date",
      );
    });
  });
  describe("withdraw from vesting", () => {
    let linearVesting: Vesting;
    let exponentialVesting: Vesting;

    beforeEach(async () => {
      let linearSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
      let exponentialSchedule = { scheduleData: linearSchedule, exponent: exponent } as Schedule;

      let tx = await vesting.createBaseSchedule(linearSchedule);
      let linearScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);

      tx = await vesting.createSchedule(exponentialSchedule);
      let exponentialScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);

      linearVesting = {
        vestingStartTime: await time.latest(),
        beneficiary: alice.address,
        vestingToken: await erc20.getAddress(),
        vestingAmount: vestingAmount,
        paidAmount: 0,
        scheduleId: linearScheduleId,
      } as Vesting;

      exponentialVesting = {
        ...linearVesting,
        scheduleId: exponentialScheduleId,
        vestingAmount: vestingAmount * 2n,
      };
    });

    it("should correctly withdraw from vesting after full duration", async () => {
      let createTx = await vesting.createVesting(linearVesting);
      let linearVestingId = ethers.toBigInt((await createTx.wait())?.logs[0].topics[1] as string);

      createTx = await vesting.createVesting(exponentialVesting);
      let exponentialVestingId = ethers.toBigInt((await createTx.wait())?.logs[0].topics[1] as string);

      expect(await vesting.getVestedAmount(linearVestingId)).to.be.equal(0);
      expect(await vesting.getWithdrawableAmount(linearVestingId)).to.be.equal(0);

      expect(await vesting.getVestedAmount(exponentialVestingId)).to.be.equal(0);
      expect(await vesting.getWithdrawableAmount(exponentialVestingId)).to.be.equal(0);

      await time.increase(secondsInPeriod * durationInPeriods);

      expect(await vesting.getVestedAmount(linearVestingId)).to.be.equal(linearVesting.vestingAmount);
      expect(await vesting.getWithdrawableAmount(linearVestingId)).to.be.equal(linearVesting.vestingAmount);

      expect(await vesting.getVestedAmount(exponentialVestingId)).to.be.equal(exponentialVesting.vestingAmount);
      expect(await vesting.getWithdrawableAmount(exponentialVestingId)).to.be.equal(exponentialVesting.vestingAmount);

      const linearTx = vesting.connect(alice).withdrawFromVesting(linearVestingId);
      const exponentialTx = vesting.connect(alice).withdrawFromVesting(exponentialVestingId);

      await expect(linearTx)
        .to.emit(vesting, "WithdrawnFromVesting")
        .withArgs(linearVestingId, linearVesting.vestingAmount);
      await expect(exponentialTx)
        .to.emit(vesting, "WithdrawnFromVesting")
        .withArgs(exponentialVestingId, exponentialVesting.vestingAmount);

      linearVesting.paidAmount = linearVesting.vestingAmount;
      exponentialVesting.paidAmount = exponentialVesting.vestingAmount;

      expect(await vesting.getVesting(linearVestingId)).to.deep.equal(Object.values(linearVesting));
      expect(await vesting.getVesting(exponentialVestingId)).to.deep.equal(Object.values(exponentialVesting));

      expect(await erc20.balanceOf(alice.address)).changeTokenBalance(
        erc20,
        alice.address,
        BigInt(linearVesting.vestingAmount) + BigInt(exponentialVesting.vestingAmount),
      );
    });

    it("should correctly withdraw from vesting after half duration", async () => {
      let createTx = await vesting.createVesting(linearVesting);
      let linearVestingId = ethers.toBigInt((await createTx.wait())?.logs[0].topics[1] as string);

      createTx = await vesting.createVesting(exponentialVesting);
      let exponentialVestingId = ethers.toBigInt((await createTx.wait())?.logs[0].topics[1] as string);

      expect(await vesting.getVestedAmount(linearVestingId)).to.be.equal(0);
      expect(await vesting.getWithdrawableAmount(linearVestingId)).to.be.equal(0);

      expect(await vesting.getVestedAmount(exponentialVestingId)).to.be.equal(0);
      expect(await vesting.getWithdrawableAmount(exponentialVestingId)).to.be.equal(0);

      // 15 days out of 30
      await time.increase((secondsInPeriod * durationInPeriods) / 2n);

      let linearVestedAmount = await calculateVestedAmount(
        BigInt(linearVesting.vestingStartTime),
        BigInt(linearVesting.vestingAmount),
        LINEAR_EXPONENT,
      );

      let exponentialVestedAmount = await calculateVestedAmount(
        BigInt(exponentialVesting.vestingStartTime),
        BigInt(exponentialVesting.vestingAmount),
        exponent,
      );

      expect(await vesting.getVestedAmount(linearVestingId)).to.be.equal(linearVestedAmount);
      expect(await vesting.getWithdrawableAmount(linearVestingId)).to.be.equal(linearVestedAmount);

      expect(await vesting.getVestedAmount(exponentialVestingId)).to.be.equal(exponentialVestedAmount);
      expect(await vesting.getWithdrawableAmount(exponentialVestingId)).to.be.equal(exponentialVestedAmount);

      await vesting.connect(alice).withdrawFromVesting(linearVestingId);
      await vesting.connect(alice).withdrawFromVesting(exponentialVestingId);

      linearVesting.paidAmount = linearVestedAmount;
      exponentialVesting.paidAmount = exponentialVestedAmount;

      expect(await vesting.getVesting(linearVestingId)).to.deep.equal(Object.values(linearVesting));
      expect(await vesting.getVesting(exponentialVestingId)).to.deep.equal(Object.values(exponentialVesting));

      expect(await vesting.getWithdrawableAmount(linearVestingId)).to.be.equal(0);
      expect(await vesting.getWithdrawableAmount(exponentialVestingId)).to.be.equal(0);

      expect(await erc20.balanceOf(alice.address)).changeTokenBalance(
        erc20,
        alice.address,
        linearVestedAmount + exponentialVestedAmount,
      );
    });

    it("should revert if non beneficiary tries to withdraw from vesting", async () => {
      await vesting.createVesting(linearVesting);

      await expect(vesting.withdrawFromVesting(1)).to.be.revertedWith(
        "VestingWallet: only beneficiary can withdraw from his vesting",
      );
    });

    it("should revert if nothing to withdraw", async () => {
      await vesting.createVesting(linearVesting);

      await time.increase(secondsInPeriod * durationInPeriods);

      await vesting.connect(alice).withdrawFromVesting(1);

      await expect(vesting.connect(alice).withdrawFromVesting(1)).to.be.revertedWith(
        "VestingWallet: nothing to withdraw",
      );
    });
  });
  describe("check calculations", () => {
    let defaultSchedule: Schedule;

    beforeEach(async () => {
      defaultSchedule = {
        scheduleData: {
          secondsInPeriod,
          durationInPeriods,
          cliffInPeriods,
        },
        exponent: exponent,
      };
    });

    it("should return 0 if vesting has not started", async () => {
      let vestingStartTime = BigInt(await time.latest());
      let timestampUpTo = 0n;

      expect(
        await vesting.vestingCalculation(defaultSchedule, vestingAmount, vestingStartTime, timestampUpTo),
      ).to.be.equal(0);
    });

    it("should return 0 if cliff is active", async () => {
      let vestingStartTime = BigInt(await time.latest());
      let timestampUpTo = vestingStartTime + secondsInPeriod;

      defaultSchedule.scheduleData.cliffInPeriods = 2n;

      expect(
        await vesting.vestingCalculation(defaultSchedule, vestingAmount, vestingStartTime, timestampUpTo),
      ).to.be.equal(0);
    });

    it("should return 0 if start time the same as timestamp up to", async () => {
      let vestingStartTime = BigInt(await time.latest());
      let timestampUpTo = vestingStartTime;

      expect(
        await vesting.vestingCalculation(defaultSchedule, vestingAmount, vestingStartTime, timestampUpTo),
      ).to.be.equal(0);
    });
  });
});
