import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";
import { ZERO_ADDR, MAX_UINT256 } from "@/scripts/utils/constants";
import { wei } from "@/scripts/utils/utils";

import { VestingMock, VestingMock__factory, ERC20Mock, ERC20Mock__factory, Vesting } from "@ethers-v6";

describe("Vesting", () => {
  let reverter = new Reverter();
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;

  let vesting: VestingMock;
  let erc20: ERC20Mock;

  type BaseSchedule = Vesting.BaseScheduleStruct;
  type Schedule = Vesting.ScheduleStruct;
  type Vesting = Vesting.VestingDataStruct;

  before(async () => {
    [owner, alice] = await ethers.getSigners();
    vesting = await new VestingMock__factory(owner).deploy();
    erc20 = await new ERC20Mock__factory(owner).deploy("Test", "TST", 18);

    reverter.snapshot();
  });

  afterEach(reverter.revert);

  it("test schedule", async () => {
    const secondsInPeriod = 60 * 60 * 24; // one day;
    const durationInPeriods = 25; // days
    const cliffInPeriods = 0;
    const vestingAmount = wei(100);
    const exponent = 0;

    let baseSchedule = { secondsInPeriod, durationInPeriods, cliffInPeriods } as BaseSchedule;
    let schedule = { scheduleData: baseSchedule, exponent: exponent } as Schedule;

    // id 1
    await vesting.createSchedule(schedule);

    let vestingData = {
      vestingStartTime: await time.latest(),
      beneficiary: alice.address,
      vestingToken: await erc20.getAddress(),
      vestingAmount: vestingAmount,
      paidAmount: 0,
      scheduleId: 1,
    } as Vesting;

    erc20.mint(owner.address, vestingAmount);
    erc20.approve(await vesting.getAddress(), vestingAmount);

    // id 1
    await vesting.createVesting(vestingData);

    console.log(`Total duration: ${durationInPeriods} Total amount: ${vestingAmount} Exponent: ${exponent}`);

    let vestedAmount: bigint = BigInt(0);
    for (let day = 0; day <= durationInPeriods; day++) {
      let previousVestedAmount = vestedAmount;
      vestedAmount = await vesting.getVestedAmount(1, await time.latest(), vestingData.vestingStartTime);

      console.log(
        `Time: ${await time.latest()} Day: ${day} Amount per day: ${
          vestedAmount - previousVestedAmount
        } Amount Total: ${vestedAmount.toString()}`
      );

      await time.increase(secondsInPeriod);
    }
  });
});
