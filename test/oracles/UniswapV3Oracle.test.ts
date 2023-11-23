import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { BigNumberish } from "ethers";
import { wei } from "@/scripts/utils/utils";

import { UniswapV3OracleMock, UniswapV3FactoryMock, UniswapV3PoolMock } from "@ethers-v6";

describe("UniswapV3Oracle", () => {
  const reverter = new Reverter();

  const A_TOKEN = "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa";
  const B_TOKEN = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
  const C_TOKEN = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";
  const A_B_PATH = [A_TOKEN, B_TOKEN];

  const PERIOD = 2;
  const enum FeeAmount {
    LOW = 500,
    MEDIUM = 3000,
  }

  let oracle: UniswapV3OracleMock;
  let uniswapV3Factory: UniswapV3FactoryMock;
  let pool: UniswapV3PoolMock;

  before("setup", async () => {
    const UniswapV3FactoryMock = await ethers.getContractFactory("UniswapV3FactoryMock");
    const Oracle = await ethers.getContractFactory("UniswapV3OracleMock");

    uniswapV3Factory = await UniswapV3FactoryMock.deploy();
    oracle = await Oracle.deploy();

    await oracle.__OracleV3Mock_init(await uniswapV3Factory.getAddress());

    await reverter.snapshot();
  });

  async function createPools(token0: string, token1: string): Promise<UniswapV3PoolMock> {
    await uniswapV3Factory.createPool(token0, token1, FeeAmount.MEDIUM);

    let poolAddress = await uniswapV3Factory.getPool(token0, token1, FeeAmount.MEDIUM);

    return <UniswapV3PoolMock>await ethers.getContractAt("UniswapV3PoolMock", poolAddress);
  }

  function encodePriceSqrt(reserve1: number, reserve0: number): BigNumberish {
    return BigInt(Math.sqrt(reserve1 / reserve0) * Math.pow(2, 96));
  }

  function getPriceByTick(tick: number, amount: BigInt): BigInt {
    return BigInt(Math.floor(1.0001 ** tick * Number(amount)));
  }

  afterEach(reverter.revert);

  describe("init", () => {
    it("should set oracle correctly", async () => {
      expect(await oracle.uniswapV3Factory()).to.equal(await uniswapV3Factory.getAddress());
    });

    it("should not initialize twice", async () => {
      await expect(oracle.mockInit(await uniswapV3Factory.getAddress())).to.be.revertedWith(
        "Initializable: contract is not initializing"
      );
      await expect(oracle.__OracleV3Mock_init(await uniswapV3Factory.getAddress())).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("getPrice", () => {
    it("should correctly get price if there are same tokens in the path ", async () => {
      let ans = await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 51, PERIOD);

      expect(ans[0]).to.equal(51);
    });

    it("should correctly get price if it older than observation", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      const timeFirst = (await time.latest()) + 2;
      await time.increaseTo(timeFirst);

      await pool.initialize(encodePriceSqrt(10 ** 6, 10 ** 18));

      await time.increaseTo(timeFirst + 3);

      let ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 5n * wei("1"), 5);

      expect(ans[0]).to.equal(getPriceByTick(Number((await pool.slot0()).tick), 5n * wei("1")));
      expect(ans[1]).to.equal((await time.latest()) - timeFirst - 1);
    });

    it("should correctly increase cardinality and overwrite observations", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      await pool.initialize(encodePriceSqrt(10 ** 3, 10 ** 12));
      await pool.increaseObservationCardinalityNext(2);

      await time.increaseTo((await time.latest()) + 1);

      await pool.addObservation(-111);

      const firstTime = await time.latest();
      await time.increaseTo(firstTime + 3);

      await pool.addObservation(250);

      let ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10n ** 6n, 3);

      expect(ans[0]).to.equal(getPriceByTick(-111, 10n ** 6n));
      expect(ans[1]).to.equal(3);
    });

    it("should correctly get price for complex path", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);
      let poolBC = await createPools(B_TOKEN, C_TOKEN);

      await pool.initialize(encodePriceSqrt(2 * 10 ** 6, 10 ** 18));
      await poolBC.initialize(encodePriceSqrt(10 ** 2, 10 ** 6));

      await time.increaseTo((await time.latest()) + 2);

      let ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, C_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        2n * wei("1"),
        PERIOD
      );

      //priceAB = 1.0001 ** tickAB * amount, priceBC = 1.0001 ** tickBC * amount,
      //so priceAC = priceAB*priceBC = amount(1.0001**(tickAB+tickBC))
      let compositeTick = Number((await pool.slot0()).tick + (await poolBC.slot0()).tick);

      expect(ans[0]).to.equal(getPriceByTick(compositeTick, 2n * wei("1")));
      expect(ans[1]).to.equal(PERIOD);

      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        2n * wei("1"),
        PERIOD
      );

      expect(Math.round(Number(ans[0]) / 10 ** 18)).to.equal(2);
      expect(ans[1]).to.equal(PERIOD);
    });

    it("should correctly get average price", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      const firstTime = (await time.latest()) + 2;

      await time.increaseTo(firstTime);
      await pool.initialize(encodePriceSqrt(1, 1)); //first observation taken at firstTime
      await pool.increaseObservationCardinalityNext(4);

      await time.increaseTo(firstTime + 3);
      await pool.addObservation(-127); //second observation taken at firstTime + 3

      await time.increaseTo(firstTime + 5);
      await pool.addObservation(-871); //third observation at firstTime + 5

      await time.increaseTo(firstTime + 8);
      await pool.addObservation(-1241); //forth observation at firstTime + 8

      let ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10 ** 6, (await time.latest()) - 1);

      let avgTick = Math.floor((0 * 3 - 127 * 2 - 871 * 3) / 8);

      expect(ans[0]).to.equal(getPriceByTick(avgTick, 10n ** 6n));
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 1); //time of first observation
    });

    it("should work correct if some observations aren't initialized", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      const timeFirst = (await time.latest()) + 2;
      await time.increaseTo(timeFirst);
      await pool.initialize(encodePriceSqrt(10 ** 6, 10 ** 3));

      await pool.increaseObservationCardinalityNext(4);
      await pool.addObservation(-111);

      let ans = await oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, 3);
      expect(ans[1]).to.equal((await time.latest()) - timeFirst - 1);
    });

    it("should return 0 if amount is 0", async () => {
      let ans = await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 0, PERIOD);

      expect(ans).to.deep.equal([0n, 0n]);
    });

    it("should not get price if there is invalid path", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN], [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: invalid path"
      );
    });

    it("should not get price if there wrong amount of fees or tokens", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, PERIOD)
      ).to.be.revertedWith("UniswapV3Oracle: path/fee lengths do not match");
    });

    it("should not get price if there is no such pool", async () => {
      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist"
      );

      pool = await createPools(A_TOKEN, B_TOKEN);
      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.LOW], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist"
      );
    });

    it("should return if pool isn't initialized", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "OracleLibrary: pool is not initialized"
      );
    });

    it("should not get price if period larger than current timestamp", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, (await time.latest()) + 10)
      ).to.be.revertedWith("UniswapV3Oracle: period larger than current timestamp");
    });

    it("should return if oldest observation is on current block", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      await pool.initialize(encodePriceSqrt(1, 1));

      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: the oldest observation is on current block"
      );
    });

    it("should not get price if period is zero", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10, 0)).to.be.revertedWith(
        "UniswapV3Oracle: period can't be 0"
      );
    });

    it("should not get price if tick bigger than max tick", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);
      await pool.initialize(encodePriceSqrt(1, 1));
      await pool.increaseObservationCardinalityNext(2);

      await pool.addObservation(900000);

      await time.increaseTo((await time.latest()) + 2);

      await expect(oracle.getPriceOfTokenInToken(A_B_PATH, [FeeAmount.MEDIUM], 1, 1)).to.be.revertedWith(
        "TickMath: invalid tick"
      );
    });

    it("should not get price if price not in range", async () => {
      pool = await createPools(A_TOKEN, B_TOKEN);

      await expect(pool.initialize(encodePriceSqrt(1, 2 ** 128))).to.be.revertedWith(
        "TickMath: sqrtPriceX96 not in range"
      );
    });
  });
});
