const { assert } = require("chai");
const { toBN, precision, fromPrecision, accounts } = require("../../scripts/utils/utils");
const { setNextBlockTime, getCurrentBlockTime } = require("../helpers/block-helper");

const truffleAssert = require("truffle-assertions");

const CompoundRateKeeper = artifacts.require("CompoundRateKeeperMock");

CompoundRateKeeper.numberFormat = "BigNumber";

const maxRate = toBN(2).pow(128).minus(1).toFixed();

describe("CompoundRateKeeper", () => {
  let SECOND;

  let crk;

  before("setup", async () => {
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    crk = await CompoundRateKeeper.new();

    await crk.__OwnableCompoundRateKeeper_init(precision(1), 31536000);
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(crk.mockInit(precision(1), 31536000), "Initializable: contract is not initializing");
      await truffleAssert.reverts(
        crk.__OwnableCompoundRateKeeper_init(precision(1), 31536000),
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await truffleAssert.reverts(
        crk.setCapitalizationRate(precision(1), { from: SECOND }),
        "Ownable: caller is not the owner"
      );

      await truffleAssert.reverts(
        crk.setCapitalizationPeriod(31536000, { from: SECOND }),
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("setCapitalizationRate()", () => {
    it("should correctly set new annual percent", async () => {
      let nextBlockTime = (await getCurrentBlockTime()) + 10;

      await setNextBlockTime(nextBlockTime);
      await crk.setCapitalizationRate(precision(1.1));

      assert.equal(fromPrecision((await crk.getCompoundRate()).toFixed()), "1");
      assert.equal(fromPrecision((await crk.getCapitalizationRate()).toFixed()), "1.1");
      assert.equal((await crk.getLastUpdate()).toFixed(), toBN(nextBlockTime).toFixed());

      nextBlockTime = (await getCurrentBlockTime()) + 31536000;

      await setNextBlockTime(nextBlockTime);
      await crk.setCapitalizationRate(precision(1.2));

      assert.equal(fromPrecision((await crk.getCompoundRate()).toFixed()), "1.1");
      assert.equal(fromPrecision((await crk.getCapitalizationRate()).toFixed()), "1.2");
      assert.equal((await crk.getLastUpdate()).toFixed(), toBN(nextBlockTime).toFixed());
    });

    it("should revert if rate is less than zero", async () => {
      await truffleAssert.reverts(crk.setCapitalizationRate(precision(0.99999)), "CRK: rate is less than 1");
    });

    it("should revert if compound rate reaches max limit", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRate(precision(5));

      await setNextBlockTime((await getCurrentBlockTime()) + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      await truffleAssert.reverts(crk.setCapitalizationRate(precision(1.1)), "CRK: max rate is reached");
    });
  });

  describe("setCapitalizationPeriod()", () => {
    it("should correctly set new capitalization period", async () => {
      assert.equal((await crk.getCapitalizationPeriod()).toFixed(), "31536000");

      await crk.setCapitalizationPeriod(10);
      assert.equal((await crk.getCapitalizationPeriod()).toFixed(), "10");

      await crk.setCapitalizationPeriod(157680000);
      assert.equal((await crk.getCapitalizationPeriod()).toFixed(), "157680000");
    });

    it("should revert if capitalization period is zero", async () => {
      await truffleAssert.reverts(crk.setCapitalizationPeriod(0), "CRK: invalid period");
    });

    it("should revert if compound rate reaches max limit", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRate(precision(5));

      await setNextBlockTime((await getCurrentBlockTime()) + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      await truffleAssert.reverts(crk.setCapitalizationPeriod(1), "CRK: max rate is reached");
    });
  });

  describe("emergencyUpdateCompoundRate()", () => {
    it("should correctly update compound rate", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRate(precision(5));

      await crk.emergencyUpdateCompoundRate();

      assert.equal(await crk.getIsMaxRateReached(), false);

      await setNextBlockTime((await getCurrentBlockTime()) + 100 * 31536000);
      await crk.emergencyUpdateCompoundRate();

      assert.equal(await crk.getIsMaxRateReached(), true);
      assert.equal((await crk.getCompoundRate()).toFixed(), precision(toBN(2).pow(128).minus(1)));

      await crk.emergencyUpdateCompoundRate();

      assert.equal(await crk.getIsMaxRateReached(), true);
      assert.equal((await crk.getCompoundRate()).toFixed(), precision(toBN(2).pow(128).minus(1)));
    });
  });

  describe("getFutureCompoundRate()", () => {
    it("check correct compound calculate for 50%, check max timestamp", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRate(precision(1.5));

      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2628000)).toFixed()),
        "1.04166666666666666667"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 8 * 2628000)).toFixed()),
        "1.33333333333333333333"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 31536000)).toFixed()),
        "1.5"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000)).toFixed()),
        "2.25"
      );
      assert.equal(
        fromPrecision(
          (await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000 + 31536000 / 4)).toFixed()
        ),
        "2.53125"
      );
      assert.equal(
        fromPrecision(
          (await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000 + 31536000 / 2)).toFixed()
        ),
        "2.8125"
      );
      assert.equal(
        fromPrecision(
          (await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000 + (31536000 / 4) * 3)).toFixed()
        ),
        "3.09375"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 5 * 31536000)).toFixed()),
        "7.59375"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 10 * 31536000)).toFixed()),
        "57.6650390625"
      );
      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 50 * 31536000)).toFixed()),
        "637621500.21404958690340780691"
      );
    });

    it("check compound rate when capitalization period changes", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRateAndPeriod(precision(1.0000001), 1);

      assert.closeTo(
        toBN(
          fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 31536000)).toFixed())
        ).toNumber(),
        23.42,
        0.01
      );

      await setNextBlockTime((await getCurrentBlockTime()) + 31536000);
      await crk.setCapitalizationRateAndPeriod(precision(1.01), 86400);

      assert.closeTo(
        toBN(
          fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000)).toFixed())
        ).toNumber(),
        33434.42,
        0.01
      );
    });

    it("check compound rate when capitalization rate changes", async () => {
      await setNextBlockTime((await getCurrentBlockTime()) + 10);
      await crk.setCapitalizationRate(precision(1.1));

      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 31536000)).toFixed()),
        "1.1"
      );

      await setNextBlockTime((await getCurrentBlockTime()) + 31536000);
      await crk.setCapitalizationRate(precision(1.2));

      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 2 * 31536000)).toFixed()),
        "1.584"
      );

      await setNextBlockTime((await getCurrentBlockTime()) + 2 * 31536000);
      await crk.setCapitalizationRate(precision(1.5));

      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 3 * 31536000)).toFixed()),
        "5.346"
      );

      await setNextBlockTime((await getCurrentBlockTime()) + 3 * 31536000);
      await crk.setCapitalizationRate(precision(1.05));

      assert.equal(
        fromPrecision((await crk.getFutureCompoundRate((await getCurrentBlockTime()) + 31536000)).toFixed()),
        "5.6133"
      );
    });

    it("check max timestamp for 10%", async () => {
      await checkByParams(1.1);
    });

    it("check max timestamp for 25%", async () => {
      await checkByParams(1.25);
    });

    it("check max timestamp for 50%", async () => {
      await checkByParams(1.5);
    });

    it("check max timestamp for 100%", async () => {
      await checkByParams(2);
    });

    it("check max timestamp for 200%", async () => {
      await checkByParams(3);
    });

    it("check max timestamp for 500%", async () => {
      await checkByParams(6);
    });

    it("check max timestamp for 1000%", async () => {
      await checkByParams(11);
    });
  });

  async function checkByParams(rate) {
    await setNextBlockTime((await getCurrentBlockTime()) + 10);
    await crk.setCapitalizationRate(precision(rate));

    let calcRate;
    let expectedRate;

    for (let y = 3; y <= 3600; y += 9) {
      try {
        calcRate = (await crk.getFutureCompoundRate((await getCurrentBlockTime()) + y * 2628000)).toFixed();

        const capitalizationPeriodsNum = Math.floor(y / 12);
        const capitalizationRate = toBN(rate).pow(capitalizationPeriodsNum);
        const leftRate = toBN(y % 12)
          .times(toBN(rate).minus(1))
          .div(12)
          .plus(1);

        expectedRate = toBN(precision(capitalizationRate.times(leftRate))).toFixed(0);

        if (toBN(expectedRate).isGreaterThan(maxRate)) {
          assert.equal(calcRate, maxRate);
        } else {
          assert.closeTo(toBN(calcRate).minus(expectedRate).toNumber(), 0, 100000000000000000000);
        }
      } catch (e) {
        return;
      }
    }
  }
});
