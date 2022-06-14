const { assert } = require("chai");
const { toBN, decimal, fromDecimal } = require("../../scripts/helpers/utils");
const { setNextBlockTime } = require("../helpers/hardhatTimeTraveller");

const truffleAssert = require("truffle-assertions");
const Reverter = require("../helpers/reverter");

const CompoundRateKeeperV2 = artifacts.require("CompoundRateKeeperV2");

describe("CompoundRateKeeperV2", () => {
  const reverter = new Reverter();
  const maxRate = toBN(2).pow(128).minus(1).toFixed();

  let crk;

  before("setup", async () => {
    reverter.snapshot();
  });

  beforeEach("setup", async () => {
    crk = await CompoundRateKeeperV2.new(decimal(1));
  });

  afterEach("setup", async () => {
    reverter.revert();
  });

  describe("setAnnualPercent()", () => {
    it("should correctly set new annual percent", async () => {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(1.1));

      assert.equal(fromDecimal((await crk.currentRate()).toString()), "1");
      assert.equal(fromDecimal((await crk.annualPercent()).toString()), "1.1");
      assert.equal((await crk.lastUpdate()).toString(), "10");

      await setNextBlockTime(10 + 31536000);
      await crk.setAnnualPercent(decimal(1.2).toString());

      assert.equal(fromDecimal((await crk.currentRate()).toString()), "1.1");
      assert.equal(fromDecimal((await crk.annualPercent()).toString()), "1.2");
      assert.equal((await crk.lastUpdate()).toString(), "31536010");
    });

    it("should revert if annual percent less then zero", async function () {
      await truffleAssert.reverts(crk.setAnnualPercent(decimal(0.99999)), "CRK: annual percent can't be less then 1");
    });

    it("should revert if compound rate reach max limit", async () => {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(5));

      await setNextBlockTime(10 + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      await truffleAssert.reverts(crk.setAnnualPercent(decimal(1.1)), "CRK: max rate has been reached");
    });
  });

  describe("setCapitalizationPeriod()", () => {
    it("should correctly set new capitalization period", async () => {
      assert.equal((await crk.capitalizationPeriod()).toString(), "31536000");

      await crk.setCapitalizationPeriod(10);
      assert.equal((await crk.capitalizationPeriod()).toString(), "10");

      await crk.setCapitalizationPeriod(157680000);
      assert.equal((await crk.capitalizationPeriod()).toString(), "157680000");
    });

    it("should revert if capitalization period is zero", async () => {
      await truffleAssert.reverts(crk.setCapitalizationPeriod(0), "CRK: invalid value");
    });

    it("should revert if compound rate reach max limit", async () => {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(5));

      await setNextBlockTime(10 + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      await truffleAssert.reverts(crk.setCapitalizationPeriod(1), "CRK: max rate has been reached");
    });
  });

  describe("emergencyUpdateCompoundRate()", () => {
    it("should correctly update compound rate", async () => {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(5).toString());

      await crk.emergencyUpdateCompoundRate();

      assert.equal(await crk.hasMaxRateReached(), false);

      await setNextBlockTime(10 + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      assert.equal(await crk.hasMaxRateReached(), true);
      assert.equal(await crk.getCompoundRate(), decimal(toBN(2).pow(128).minus(1)).toString());
    });
  });

  describe("getPotentialCompoundRate()", function () {
    it("check correct compound calculate for 50%, check max timestamp", async function () {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(1.5).toString());

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 2628000)).toString()),
        "1.04166666666666666667"
      );

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 8 * 2628000)).toString()),
        "1.33333333333333333333"
      );

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 31536000)).toString()), "1.5");

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 2 * 31536000)).toString()), "2.25");

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 2 * 31536000 + 31536000 / 4)).toString()),
        "2.53125"
      );

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 2 * 31536000 + 31536000 / 2)).toString()),
        "2.8125"
      );

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 2 * 31536000 + (31536000 / 4) * 3)).toString()),
        "3.09375"
      );

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 5 * 31536000)).toString()), "7.59375");

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 10 * 31536000)).toString()), "57.6650390625");

      assert.equal(
        fromDecimal((await crk.getPotentialCompoundRate(10 + 50 * 31536000)).toString()),
        "637621500.21404958690340780691"
      );
    });

    it("check compound rate when change annual percent", async function () {
      await setNextBlockTime(10);
      await crk.setAnnualPercent(decimal(1.1).toString());

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 31536000)).toString()), "1.1");

      await setNextBlockTime(10 + 31536000);
      await crk.setAnnualPercent(decimal(1.2).toString());

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 3 * 31536000)).toString()), "1.584");

      await setNextBlockTime(10 + 3 * 31536000);
      await crk.setAnnualPercent(decimal(1.5).toString());

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 6 * 31536000)).toString()), "5.346");

      await setNextBlockTime(10 + 6 * 31536000);
      await crk.setAnnualPercent(decimal(1.05).toString());

      assert.equal(fromDecimal((await crk.getPotentialCompoundRate(10 + 7 * 31536000)).toString()), "5.6133");
    });

    it("check max timestamp for 10%", async function () {
      await checkByParams(1.1);
    });

    it("check max timestamp for 25%", async function () {
      await checkByParams(1.25);
    });

    it("check max timestamp for 50%", async function () {
      await checkByParams(1.5);
    });

    it("check max timestamp for 100%", async function () {
      await checkByParams(2);
    });

    it("check max timestamp for 200%", async function () {
      await checkByParams(3);
    });

    it("check max timestamp for 500%", async function () {
      await checkByParams(6);
    });

    it("check max timestamp for 1000%", async function () {
      await checkByParams(11);
    });
  });

  async function checkByParams(annualPercent) {
    await setNextBlockTime(10);
    await crk.setAnnualPercent(decimal(annualPercent).toString());

    let calcRate;
    let expectRate;
    for (let y = 3; y <= 3600; y += 3) {
      try {
        calcRate = (await crk.getPotentialCompoundRate(10 + y * 2628000)).toString();

        const capitalizationPeriodsNum = Math.floor(y / 12);
        const capitalizationRate = toBN(annualPercent).pow(capitalizationPeriodsNum);
        const leftRate = toBN(y % 12)
          .multipliedBy(toBN(annualPercent).minus(1))
          .dividedBy(12)
          .plus(1);
        expectRate = toBN(decimal(capitalizationRate.multipliedBy(leftRate))).toFixed(0);

        if (toBN(expectRate).isGreaterThan(maxRate)) {
          assert.equal(calcRate, maxRate);
        } else {
          assert.closeTo(toBN(calcRate).minus(expectRate).toNumber(), 0, 100000000000000000000);
        }
      } catch (e) {
        console.log(
          `Base percent: ${toBN(annualPercent)
            .minus(1)
            .multipliedBy(100)
            .toString()}%. Max rate will be reached at ${y} month.`
        );
        return;
      }
    }

    console.log(`Base percent: ${toBN(annualPercent).minus(1).multipliedBy(100).toString()}%. Done.`);
  }
});
