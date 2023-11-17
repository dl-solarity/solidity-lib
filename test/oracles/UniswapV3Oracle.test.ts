import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { BigNumberish } from "ethers";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { UniswapV3OracleMock, UniswapV3FactoryMock, UniswapV3PoolMock } from "@ethers-v6";

describe("UniswapV3Oracle", () => {
  const reverter = new Reverter();

  const PERIOD = 2;
  const enum FeeAmount {
    LOW = 500,
    MEDIUM = 3000,
  }

  let oracle: UniswapV3OracleMock;
  let uniswapV3Factory: UniswapV3FactoryMock;
  let pool: UniswapV3PoolMock;
  let a_token, b_token: string;

  before("setup", async () => {
    const UniswapV3FactoryMock = await ethers.getContractFactory("UniswapV3FactoryMock");
    const Oracle = await ethers.getContractFactory("UniswapV3OracleMock");

    uniswapV3Factory = await UniswapV3FactoryMock.deploy();
    oracle = await Oracle.deploy();

    await oracle.__OracleV3Mock_init(await uniswapV3Factory.getAddress());

    await reverter.snapshot();
  });

  async function createPools(token1: string, token2: string): Promise<UniswapV3PoolMock> {
    await uniswapV3Factory.createPool(token1, token2, FeeAmount.MEDIUM);

    let poolAddress = await uniswapV3Factory.getPool(token1, token2, FeeAmount.MEDIUM);

    return <UniswapV3PoolMock>await ethers.getContractAt("UniswapV3PoolMock", poolAddress);
  }

  async function deployTokens(tokens: string[], decimals: number[]): Promise<string[]> {
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    let result: string[] = [];

    for (var i = 0; i < tokens.length; i++) {
      const t = await ERC20Mock.deploy(tokens[i], tokens[i], decimals[i]);
      result[i] = await t.getAddress();
    }

    return result;
  }

  function encodePriceSqrt(reserve1: number, reserve0: number): BigNumberish {
    return BigInt(Math.sqrt(reserve1 / reserve0) * Math.pow(2, 96));
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
      [a_token] = await deployTokens(["A"], [3]);
      let ans = await oracle.getPriceOfTokenInToken([a_token, a_token], [FeeAmount.MEDIUM], 51, PERIOD);

      expect(ans[0]).to.equal(51);
    });

    it("should correctly get price if it older than observation", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [18, 2]);

      pool = await createPools(a_token, b_token);

      const timeFirst = (await time.latest()) + 2;

      await time.increaseTo(timeFirst);

      await pool.initialize(encodePriceSqrt(1, 1));

      await time.increaseTo(timeFirst + 3);

      let ans = await oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 5n * 10n ** 18n, 5);

      expect(ans[0]).to.equal(500);
      expect(ans[1]).to.equal((await time.latest()) - timeFirst - 1);
    });

    it("should correctly increase cardinality and overwrite observations", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [12, 3]);

      pool = await createPools(a_token, b_token);

      await pool.initialize(encodePriceSqrt(1, 1));
      await pool.increaseObservationCardinalityNext(2);

      await time.increaseTo((await time.latest()) + 1);

      await pool.addObservation(-111);

      const firstTime = await time.latest();
      await time.increaseTo(firstTime + 3);

      await pool.addObservation(250);

      let ans = await oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 10n ** 18n, 3);

      if (a_token < b_token) {
        expect(ans[0]).to.equal(Math.floor(1.0001 ** -111 * 1000) * 10 ** 6);
      } else {
        expect(ans[0]).to.equal(Math.floor(1.0001 ** 111 * 1000) * 10 ** 6);
      }

      expect(ans[1]).to.equal(3);
    });

    it("should correctly get price for complex path", async () => {
      let c_token;
      [a_token, b_token, c_token] = await deployTokens(["A", "B", "C"], [18, 6, 2]);

      pool = await createPools(a_token, b_token);
      let poolBC = await createPools(b_token, c_token);

      if (a_token < b_token) {
        await pool.initialize(encodePriceSqrt(2, 1));
      } else {
        await pool.initialize(encodePriceSqrt(1, 2));
      }

      await poolBC.initialize(encodePriceSqrt(1, 1));

      await time.increaseTo((await time.latest()) + 2);

      let ans = await oracle.getPriceOfTokenInToken(
        [a_token, b_token, c_token],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        2n * 10n ** 18n,
        PERIOD
      );

      expect(Math.round(Number(ans[0]) / 100)).to.equal(4);
      expect(ans[1]).to.equal(2);

      ans = await oracle.getPriceOfTokenInToken(
        [a_token, b_token, a_token],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        2n * 10n ** 18n,
        PERIOD
      );

      expect(Math.round(Number(ans[0]) / 10 ** 18)).to.equal(2);
      expect(ans[1]).to.equal(2);
    });

    it("should correctly get average price", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [6, 6]);
      pool = await createPools(a_token, b_token);

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

      let ans = await oracle.getPriceOfTokenInToken(
        [a_token, b_token],
        [FeeAmount.MEDIUM],
        10 ** 6,
        (await time.latest()) - 1
      );

      let avgTick = Math.floor((0 * 3 - 127 * 2 - 871 * 3) / 8);

      if (a_token < b_token) {
        expect(ans[0]).to.equal(Math.floor(1.0001 ** avgTick * 10 ** 6));
      } else {
        expect(ans[0]).to.equal(Math.floor(1.0001 ** -avgTick * 10 ** 6));
      }
      expect(ans[1]).to.equal((await time.latest()) - firstTime - 1); //time of first observation
    });

    it("should correctly get price with huge tick", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [24, 24]);
      pool = await createPools(a_token, b_token);

      await pool.initialize(encodePriceSqrt(1, 1));
      await pool.increaseObservationCardinalityNext(3);

      await time.increaseTo((await time.latest()) + 1);
      await pool.addObservation(500000);

      await time.increaseTo((await time.latest()) + 3);

      let ans = await oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 10n ** 48n, PERIOD);

      if (a_token < b_token) {
        expect(ans[0] / 10n ** 59n).to.equal(Math.floor(1.0001 ** 500000 / 10 ** 11)); //not very precise for so big tick
      } else {
        expect(ans[0] / 10n ** 24n).to.equal(Math.floor(1.0001 ** -500000 * 10 ** 24));
      }
      expect(ans[1]).to.equal(PERIOD);

      //reverse
      ans = await oracle.getPriceOfTokenInToken([b_token, a_token], [FeeAmount.MEDIUM], 10n ** 24n, PERIOD);

      if (a_token < b_token) {
        expect(ans[0]).to.equal(Math.floor(1.0001 ** -500000 * 10 ** 24));
      } else {
        expect(ans[0] / 10n ** 35n).to.equal(Math.floor(1.0001 ** 500000 / 10 ** 11));
      }
    });

    it("should return 0 if amount is 0", async () => {
      [a_token] = await deployTokens(["A"], [3]);
      let ans = await oracle.getPriceOfTokenInToken([a_token, a_token], [FeeAmount.MEDIUM], 0, PERIOD);

      expect(ans).to.deep.equal([0n, 0n]);
    });

    it("should not get price if there is invalid path", async () => {
      await expect(oracle.getPriceOfTokenInToken([ZERO_ADDR], [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: invalid path"
      );
    });

    it("should not get price if there wrong amount of fees or tokens", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([ZERO_ADDR, ZERO_ADDR, ZERO_ADDR], [FeeAmount.MEDIUM], 10, PERIOD)
      ).to.be.revertedWith("UniswapV3Oracle: path/fee lengths do not match");
    });

    it("should not get price if there is no such pool", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [18, 6]);

      await expect(
        oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 10, PERIOD)
      ).to.be.revertedWith("UniswapV3Oracle: such pool doesn't exist");

      pool = await createPools(a_token, b_token);
      await expect(oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.LOW], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist"
      );
    });

    it("should not get price if period larger than current timestamp", async () => {
      await expect(
        oracle.getPriceOfTokenInToken([ZERO_ADDR, ZERO_ADDR], [FeeAmount.MEDIUM], 10, (await time.latest()) + 10)
      ).to.be.revertedWith("UniswapV3Oracle: period larger than current timestamp");
    });

    it("should return if oldest observation is on current block", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [18, 6]);
      pool = await createPools(a_token, b_token);

      await pool.initialize(encodePriceSqrt(1, 1));

      await expect(
        oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 10, PERIOD)
      ).to.be.revertedWith("UniswapV3Oracle: the oldest observation is on current block");
    });

    it("should not get price if period is zero", async () => {
      await expect(oracle.getPriceOfTokenInToken([ZERO_ADDR, ZERO_ADDR], [FeeAmount.MEDIUM], 10, 0)).to.be.revertedWith(
        "UniswapV3Oracle: period can't be 0"
      );
    });

    it("should not get price if tick bigger than max tick", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [6, 6]);
      pool = await createPools(a_token, b_token);
      await pool.initialize(encodePriceSqrt(1, 1));
      await pool.increaseObservationCardinalityNext(2);

      await pool.addObservation(900000);

      await time.increaseTo((await time.latest()) + 2);

      await expect(oracle.getPriceOfTokenInToken([a_token, b_token], [FeeAmount.MEDIUM], 1, 1)).to.be.revertedWith(
        "TickHelper: invalid tick"
      );
    });

    it("should not get price if price not in range", async () => {
      [a_token, b_token] = await deployTokens(["A", "B"], [6, 6]);
      pool = await createPools(a_token, b_token);

      if (a_token < b_token) {
        await expect(pool.initialize(encodePriceSqrt(1, 2 ** 128))).to.be.revertedWith(
          "TickHelper: sqrtPriceX96 not in range"
        );
      } else {
        await expect(pool.initialize(encodePriceSqrt(2 ** -128, 1))).to.be.revertedWith(
          "TickHelper: sqrtPriceX96 not in range"
        );
      }
    });
  });
});
