const { assert } = require("chai");
const { accounts, wei, fromWei, decimal, fromDecimal } = require("../../scripts/helpers/utils");
const { setNextBlockTime, setTime } = require("../helpers/hardhatTimeTraveller");

const truffleAssert = require("truffle-assertions");
const Reverter = require("../helpers/reverter");

const ERC20Mock = artifacts.require("ERC20Mock");
const Staking = artifacts.require("Staking");

describe("Staking", () => {
  const reverter = new Reverter();

  const startTimestamp = 100;
  const endTimestamp = 5 * 31536000;
  const lockPeriod = 500;

  let ivan, oleg;
  let staking, erc20;

  before("setup", async () => {
    ivan = await accounts(1);
    oleg = await accounts(2);

    reverter.snapshot();
  });

  beforeEach("setup", async () => {
    erc20 = await ERC20Mock.new("20S", "20N", 18);
    staking = await Staking.new(erc20.address, startTimestamp, endTimestamp, lockPeriod, decimal(1));
  });

  afterEach("setup", async () => {
    reverter.revert();
  });

  describe("constructor()", () => {
    it("should correctly set values in storage", async () => {
      assert.equal(await staking.token(), erc20.address);

      assert.equal((await staking.startTimestamp()).toNumber(), startTimestamp);
      assert.equal((await staking.endTimestamp()).toNumber(), endTimestamp);
      assert.equal((await staking.lockPeriod()).toNumber(), lockPeriod);
    });

    it("should revert if start timestamp less pr equal than block.timestamp", async () => {
      await setNextBlockTime(10);

      try {
        await Staking.new(erc20.address, 10, 15, 1, decimal(1));
        assert.equal(1, 2);
      } catch (e) {
        assert.include(e.message, "Staking: incorrect timestamps");
      }
    });

    it("should revert if start timestamp more or equal end timestamp", async () => {
      try {
        await Staking.new(erc20.address, 10, 10, 1, decimal(1));
        assert.equal(1, 2);
      } catch (e) {
        assert.include(e.message, "Staking: incorrect timestamps");
      }
    });
  });

  describe("stake()", () => {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.mint(oleg, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
      await erc20.approve(staking.address, wei("1000"), { from: oleg });
    });

    it("should correctly stake once", async () => {
      // 5%
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.05"));

      await setNextBlockTime(100 + 2628000);
      await staking.stake(wei("100"), { from: ivan });

      let stakeInfo = await staking.addressToStake(ivan);

      // 100 / ((1,05 − 1) / 31536000 × (2628000) + 1)
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "99.585062240663900414");
      assert.equal(fromWei(stakeInfo.amount.toString()), "100");
      assert.equal(stakeInfo.lastUpdate.toString(), "2628100");

      await setNextBlockTime(100 + 100 + 2628000);
      await staking.stake(wei("100"), { from: oleg });

      stakeInfo = await staking.addressToStake(oleg);

      // 100 / ((1,05 − 1) / 31536000 × (2628000 + 100) + 1)
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "99.585046517073312448");
      assert.equal(fromWei(stakeInfo.amount.toString()), "100");
      assert.equal(stakeInfo.lastUpdate.toString(), "2628200");
    });

    it("should correctly restake, percent per year is not changed", async () => {
      // 5%
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.05"));

      // newNormalize = ((oldNormalize * rate) + amount) / rate

      // rate: 1,004166666666666666666666666
      // amount: 100
      // normalizedAmount: 99,585062240663900414
      await setNextBlockTime(100 + 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // rate: 1,0125
      // amount: 200
      // normalizedAmount: 198,350494339429332512
      await setNextBlockTime(100 + 3 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // rate: 1,0255
      // amount: 300
      // normalizedAmount: 295,911469949185430072
      await setNextBlockTime(100 + 6 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // rate: 1,05
      // amount: 400
      // normalizedAmount: 391,149565187280668166
      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // rate: 1,1025
      // amount: 500
      // normalizedAmount: 481,852513033085656828
      await setNextBlockTime(100 + 24 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      const stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "481.852513033085656828");
      assert.equal(fromWei(stakeInfo.amount.toString()), "500");
      assert.equal(stakeInfo.lastUpdate.toString(), "63072100");
    });

    it("should correctly restake, percent per year is changed", async () => {
      // 5%
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.05"));

      // rate: 1,004166666666666666666666666
      // amount: 100
      // normalizedAmount: 99,585062240663900414
      await setNextBlockTime(100 + 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // 10%
      // rate: 1,008333333333333333333333333
      await setNextBlockTime(100 + 2 * 2628000);
      await staking.setAnnualPercent(decimal("1.1"));

      // rate: 1,016736111111111111111111110
      // amount: 200
      // normalizedAmount: 197,938999813234080045
      await setNextBlockTime(100 + 3 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      // 100%
      // rate: 1,0419444444444444444444444441
      await setNextBlockTime(100 + 6 * 2628000);
      await staking.setAnnualPercent(decimal("2"));

      // rate: 1,5629166666666666666666666661
      // amount: 300
      // normalizedAmount: 261,921937696465218407
      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      const stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "261.921937696465218407");
      assert.equal(fromWei(stakeInfo.amount.toString()), "300");
      assert.equal(stakeInfo.lastUpdate.toString(), "31536100");
    });

    it("should revert if amount is zero", async () => {
      await truffleAssert.reverts(staking.stake("0"), "Staking: amount can't be a zero");
    });

    it("should revert if staking not started", async () => {
      await setNextBlockTime(startTimestamp - 1);
      await truffleAssert.reverts(staking.stake("1", { from: ivan }), "Staking: staking is not started");
    });

    it("should revert if staking is ended", async () => {
      await setNextBlockTime(endTimestamp + 1);
      await truffleAssert.reverts(staking.stake("1", { from: ivan }), "Staking: staking is ended");
    });
  });

  describe("withdraw()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.mint(staking.address, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
    });

    it("should correctly withdraw all token for one transaction", async () => {
      // 60%
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      await setNextBlockTime(100 + 24 * 2628000);
      await staking.withdraw(wei("10000"), { from: ivan });

      const stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "0");
      assert.equal(fromWei(stakeInfo.amount.toString()), "0");
      assert.equal(fromWei((await erc20.balanceOf(ivan)).toString()), "1060");
      assert.equal(fromWei((await erc20.balanceOf(staking.address)).toString()), "940");
    });

    it("should correctly withdraw all token for few transactions", async () => {
      // 60%
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100"), { from: ivan });

      await setNextBlockTime(100 + 24 * 2628000);
      await staking.withdraw(wei("60"), { from: ivan });

      let stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "39.0625");
      assert.equal(fromWei(stakeInfo.amount.toString()), "100");

      await setNextBlockTime(100 + 36 * 2628000);
      await staking.withdraw(wei("80"), { from: ivan });

      stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "19.53125");
      assert.equal(fromWei(stakeInfo.amount.toString()), "80");

      await setNextBlockTime(100 + 48 * 2628000);
      await staking.withdraw(wei("100000"), { from: ivan });

      stakeInfo = await staking.addressToStake(ivan);
      assert.equal(fromWei(stakeInfo.normalizedAmount.toString()), "0");
      assert.equal(fromWei(stakeInfo.amount.toString()), "0");
      assert.equal(fromWei((await erc20.balanceOf(ivan)).toString()), "1168");
      assert.equal(fromWei((await erc20.balanceOf(staking.address)).toString()), "832");
    });

    it("should revert if withdraw amount is zero", async () => {
      await truffleAssert.reverts(staking.withdraw("0"), "Staking: amount can't be a zero");
    });

    it("should revert if available amount is zero", async () => {
      await setNextBlockTime(lockPeriod + 1);
      await truffleAssert.reverts(staking.withdraw("1"), "Staking: nothing to withdraw");
    });

    it("should revert if still in lockup period", async () => {
      await setNextBlockTime(300);
      await staking.stake(wei("100"), { from: ivan });

      await setNextBlockTime(300 + lockPeriod);
      await truffleAssert.reverts(staking.withdraw("10000", { from: ivan }), "Staking: tokens locked");
    });
  });

  describe("getAvailableAmount()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
    });

    it("should correctly return denormalized amount", async () => {
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100").toString(), { from: ivan });
      assert.equal(fromWei((await staking.getAvailableAmount(ivan)).toString()), "100");

      await setNextBlockTime(100 + 24 * 2628000);
      await staking.stake(wei("100").toString(), { from: ivan });
      assert.equal(fromWei((await staking.getAvailableAmount(ivan)).toString()), "260");

      await setNextBlockTime(100 + 36 * 2628000);
      await staking.stake(wei("100").toString(), { from: ivan });
      assert.equal(fromWei((await staking.getAvailableAmount(ivan)).toString()), "516");
    });
  });

  describe("getPotentialAmount()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
    });

    it("should correctly return potential amount", async () => {
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 31536000);
      await staking.stake(wei("100").toString(), { from: ivan });

      assert.equal(fromWei((await staking.getPotentialAmount(ivan, 100 + 2 * 31536000)).toString()), "160");
      assert.equal(fromWei((await staking.getPotentialAmount(ivan, 100 + 6 * 31536000)).toString()), "1048.576");
      assert.equal(fromWei((await staking.getPotentialAmount(ivan, 100 + 11 * 31536000)).toString()), "10995.11627776");
    });
  });

  describe("supplyRewardPool()", function () {
    it("should correctly supply reward pool", async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.approve(staking.address, wei("500"), { from: ivan });

      await staking.supplyRewardPool(wei("300"), { from: ivan });
      assert.equal(fromWei((await erc20.balanceOf(staking.address)).toString()), "300");

      await staking.supplyRewardPool(wei("200"), { from: ivan });
      assert.equal(fromWei((await erc20.balanceOf(staking.address)).toString()), "500");
    });
  });

  describe("getAggregatedAmount() and getAggregatedNormalizedAmount()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.mint(oleg, wei("1000"));
      await erc20.mint(staking.address, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
      await erc20.approve(staking.address, wei("1000"), { from: oleg });
    });

    it("should correctly calculate aggregated amount", async () => {
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      // START stake
      await setNextBlockTime(100 + 12 * 2628000);
      await staking.stake(wei("100"), { from: ivan });
      assert.equal(fromWei((await staking.aggregatedAmount()).toString()), "100");
      assert.equal(fromWei((await staking.aggregatedNormalizedAmount()).toString()), "62.5");

      await setNextBlockTime(100 + 13 * 2628000);
      await staking.stake(wei("100"), { from: oleg });
      assert.equal(fromWei((await staking.aggregatedAmount()).toString()), "200");
      assert.equal(fromWei((await staking.aggregatedNormalizedAmount()).toString()), "122.023809523809523809");
      // END

      // START withdraw
      await setNextBlockTime(100 + 24 * 2628000);
      await staking.withdraw(wei("60"), { from: ivan });
      assert.equal(fromWei((await staking.aggregatedAmount()).toString()), "200");
      assert.equal(fromWei((await staking.aggregatedNormalizedAmount()).toString()), "98.586309523809523809");

      await setNextBlockTime(100 + 25 * 2628000);
      await staking.withdraw(wei("80"), { from: oleg });
      assert.equal(fromWei((await staking.aggregatedAmount()).toString()), "179.999999999999999998");
      assert.equal(fromWei((await staking.aggregatedNormalizedAmount()).toString()), "68.824404761904761904");

      await setNextBlockTime(100 + 30 * 2628000);
      await staking.withdraw(wei("1000"), { from: ivan });
      await staking.withdraw(wei("1000"), { from: oleg });

      assert.equal(fromWei((await staking.aggregatedAmount()).toString()), "0");
      assert.equal(fromWei((await staking.aggregatedNormalizedAmount()).toString()), "0");
    });
  });

  describe("monitorSecurityMargin()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
    });

    it("should correctly calculate security margin", async () => {
      assert.equal(fromDecimal((await staking.monitorSecurityMargin()).toString()), "1");

      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 31536000);
      await staking.stake(wei("100"), { from: ivan });

      await setTime(100 + 2 * 31536000);
      assert.equal(fromDecimal((await staking.monitorSecurityMargin()).toString()), "0.625");

      await setNextBlockTime(100 + 3 * 31536000);
      await erc20.mint(staking.address, wei("200"));
      assert.equal(fromDecimal((await staking.monitorSecurityMargin()).toString()), "1.171875");
    });
  });

  describe("withdrawERC20()", function () {
    beforeEach(async () => {
      await erc20.mint(ivan, wei("1000"));
      await erc20.mint(staking.address, wei("1000"));
      await erc20.approve(staking.address, wei("1000"), { from: ivan });
    });

    it("should correctly transfer stuck ERC20, all", async () => {
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      await setNextBlockTime(100 + 31536000);
      await staking.stake(wei("100"), { from: ivan });

      await setNextBlockTime(100 + 2 * 31536000);
      await staking.withdrawERC20(erc20.address, wei("1000"), oleg);

      assert.equal(fromWei((await erc20.balanceOf(oleg)).toString()), "940");
    });

    it("should correctly transfer stuck ERC20, parts", async () => {
      await setNextBlockTime(100);
      await staking.setAnnualPercent(decimal("1.6"));

      //1100 + 60 rewards - 500 = 600 + rewards
      await setNextBlockTime(100 + 31536000);
      await staking.stake(wei("100"), { from: ivan });
      await staking.withdrawERC20(erc20.address, wei("500"), oleg);

      await setNextBlockTime(100 + 2 * 31536000);
      await staking.withdrawERC20(erc20.address, wei("500"), ivan);

      assert.equal(fromWei((await erc20.balanceOf(oleg)).toString()), "500");
      assert.equal(fromWei((await erc20.balanceOf(ivan)).toString()), "1340");
    });
  });
});
