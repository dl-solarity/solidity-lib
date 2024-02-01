import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";
import { ZERO_ADDR, MAX_UINT256 } from "@/scripts/utils/constants";
import { wei, precision } from "@/scripts/utils/utils";

import { VestingMock, VestingMock__factory, ERC20Mock, ERC20Mock__factory, Vesting } from "@ethers-v6";
import { scheduler } from "timers/promises";
import exp from "constants";

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
  const cliffInPeriods = 0n;
  const vestingAmount = wei(100_000);
  const exponent = 3n;

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

    beforeEach(async () => {
      linearSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
      exponentialSchedule = { scheduleData: linearSchedule, exponent: exponent } as Schedule;

      let tx = await vesting.createBaseSchedule(linearSchedule);
      linearScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);

      tx = await vesting.createSchedule(exponentialSchedule);
      exponentialScheduleId = ethers.toBigInt((await tx.wait())?.logs[0].topics[1] as string);
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
    });
  });
  describe("withdraw from vesting", () => {});
  describe("check calculations", () => {});

  // it("test schedule", async () => {
  //   const secondsInPeriod = 60 * 60 * 24; // one day;
  //   const durationInPeriods = 25; // days
  //   const cliffInPeriods = 0;
  //   const vestingAmount = wei(100);
  //   const exponent = 3;

  //   let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
  //   let schedule = { scheduleData: baseSchedule, exponent: exponent } as Schedule;

  //   // id 1
  //   await vesting.createSchedule(schedule);

  //   let vestingData = {
  //     vestingStartTime: await time.latest(),
  //     beneficiary: alice.address,
  //     vestingToken: await erc20.getAddress(),
  //     vestingAmount: vestingAmount,
  //     paidAmount: 0,
  //     scheduleId: 1,
  //   } as Vesting;

  //   erc20.mint(owner.address, vestingAmount);
  //   erc20.approve(await vesting.getAddress(), vestingAmount);

  //   // id 1
  //   await vesting.createVesting(vestingData);

  //   console.log(`Total duration: ${durationInPeriods} Total amount: ${vestingAmount} Exponent: ${exponent}`);

  //   let vestedAmount: bigint = BigInt(0);
  //   for (let day = 0; day <= durationInPeriods; day++) {
  //     let previousVestedAmount = vestedAmount;
  //     vestedAmount = await vesting.getVestedAmount(1);

  //     console.log(
  //       `Time: ${await time.latest()} Day: ${day} Amount per day: ${
  //         vestedAmount - previousVestedAmount
  //       } Amount Total: ${vestedAmount.toString()}`,
  //     );

  //     await time.increase(secondsInPeriod);
  //   }
  // });
});
