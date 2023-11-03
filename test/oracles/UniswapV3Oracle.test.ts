import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { BigNumberish } from "ethers";

import { UniswapV3OracleMock, UniswapV3FactoryMock, UniswapV3PoolMock } from "@ethers-v6";

//why 0?
//swap?

describe("UniswapV3Oracle", () => {
  const reverter = new Reverter();

  const PERIOD = 2;

  const A_TOKEN = "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa";
  const B_TOKEN = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
  const C_TOKEN = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";
  const A_C_PATH = [A_TOKEN, C_TOKEN];
  const C_A_C_PATH = [C_TOKEN, A_TOKEN, C_TOKEN];
  const B_A_C_PATH = [B_TOKEN, A_TOKEN, C_TOKEN];

  const enum FeeAmount {
    LOW = 500,
    MEDIUM = 3000,
    HIGH = 10000,
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

  async function createPools(token1: string, token2: string): Promise<UniswapV3PoolMock> {
    await uniswapV3Factory.createPool(token1, token2, FeeAmount.MEDIUM);

    let poolAddress = await uniswapV3Factory.getPool(token1, token2, FeeAmount.MEDIUM);

    return <UniswapV3PoolMock>await ethers.getContractAt("UniswapV3PoolMock", poolAddress);
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
    it("should correctly get price", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);

      await pool.initialize(encodePriceSqrt(1, 1));

      await time.increaseTo((await time.latest()) + 5);

      let ans = await oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, PERIOD);

      expect(ans[0]).to.equal(10);
      expect(ans[1]).to.equal(PERIOD);
    });

    it("should correctly get price if there are same tokens in the path ", async () => {
      let ans = await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 5, PERIOD);

      expect(ans[0]).to.equal(5);
    });

    it("should correctly get price if it older than observation", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);

      const timeFirst = (await time.latest()) + 2;

      await time.increaseTo(timeFirst);

      await pool.initialize(encodePriceSqrt(1, 1));

      await time.increaseTo(timeFirst + 3);

      let ans = await oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 5, 5);

      expect(ans[0]).to.equal(5);
      expect(ans[1]).to.equal((await time.latest()) - timeFirst - 1);
    });

    it("should correctly increase cardinality and overwrite observations", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);

      await pool.initialize(encodePriceSqrt(1, 1));

      await pool.increaseObservationCardinalityNext(2);

      await pool.addObservation(100);

      await time.increaseTo((await time.latest()) + 5);

      await pool.addObservation(10000);

      let ans = await oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, 5);

      expect(ans[0]).to.equal(20);
      expect(ans[1]).to.equal(5);
    });

    it.only("should correctly get period", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      const firstTime = await time.latest();

      await time.increaseTo(firstTime + 3);
      await pool.initialize(encodePriceSqrt(1, 1)); //first observation at firstTime + 3 AC pool
      await pool.increaseObservationCardinalityNext(2);

      await time.increaseTo((await time.latest()) + 2);
      await pool.addObservation(100000); //second observation at ~firstTime + 6 AC pool

      await poolAB.initialize(encodePriceSqrt(1, 3)); //first observation in AB pool

      await time.increaseTo((await time.latest()) + 2);
      let ans = await oracle.getPriceOfTokenInToken(B_A_C_PATH, [FeeAmount.MEDIUM, FeeAmount.MEDIUM], 11, PERIOD);
      console.log("bac aft 1 obs", ans[0], " ", ans[1]);

      await pool.addObservation(400000);
      await time.increaseTo((await time.latest()) + 2);

      expect(ans[0]).to.equal(33);
      expect(ans[1]).to.equal(PERIOD);
      //AC good, CA  - not!
      ans = await oracle.getPriceOfTokenInToken(
        C_A_C_PATH,
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        11,
        //PERIOD
        (await time.latest()) - firstTime
      );

      console.log("cac", ans[0], " ", ans[1]); //что-то либо с фукнций нахождения минимального, либо с значениями инициализации

      ans = await oracle.getPriceOfTokenInToken(
        C_A_C_PATH,
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        11,
        PERIOD
      );

      console.log("cac", ans[0], " ", ans[1]);

      ans = await oracle.getPriceOfTokenInToken(
        [C_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM],
        1,
        PERIOD
      );
      console.log("ca", ans[0], " ", ans[1]);

      // expect(ans[0]).to.equal(0); //is it rigth?
      //expect(ans[1]).to.equal((await time.latest()) - firstTime - 4);

      //console.log(ans[1]);
      //console.log(await time.latest() - firstTime - 4);

      ans = await oracle.getPriceOfTokenInToken(
        B_A_C_PATH,
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        11,
        (await time.latest()) - firstTime
      );
      console.log("bac aft 2 obs", ans[0]);

      ans = await oracle.getPriceOfTokenInToken(
        A_C_PATH,
        [FeeAmount.MEDIUM],
        1,
        (await time.latest()) - firstTime
      );
      console.log("ac", ans[0], " ", ans[1]);

      ans = await oracle.getPriceOfTokenInToken(
        A_C_PATH,
        [FeeAmount.MEDIUM],
        1,
        PERIOD
      );
      console.log("ac", ans[0], " ", ans[1]);


      ans = await oracle.getPriceOfTokenInToken(
        [C_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM],
        1,
        (await time.latest()) - firstTime
      );
      console.log("ca", ans[0]);


     // expect(ans[0]).to.equal(9999); //is it rigth?
     // expect(ans[1]).to.equal(PERIOD);

      //console.log(ans[1]);

      //just curious

      ans = await oracle.getPriceOfTokenInToken([B_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 11, PERIOD);
      console.log("BA", ans[0]);

      await poolAB.addObservation(150000);
      await time.increaseTo((await time.latest()) + 2);

      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        11,
        PERIOD
      );
      console.log("ABA:", ans[0]);

      await poolAB.addObservation(550000);
      await time.increaseTo((await time.latest()) + 2);

      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN],
        [FeeAmount.MEDIUM],
        11,
        PERIOD
      );
      console.log("AB:", ans[0], " ", ans[1]);

      ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN],
        [FeeAmount.MEDIUM],
        11,
        (await time.latest()) - firstTime
      );
      console.log("AB:", ans[0], " ", ans[1]);
    });

    it("should test", async () => {
      const poolAB = await createPools(A_TOKEN, B_TOKEN);

      await poolAB.initialize(encodePriceSqrt(1, 4));

      await time.increaseTo((await time.latest()) + 1);

      //await poolAB.changeTick(5027);

      console.log("tick:", (await poolAB.slot0()).tick);

      let ans = await oracle.getPriceOfTokenInToken(
        [A_TOKEN, B_TOKEN, A_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        10000,
        2
      );
      console.log("aba :", ans[0]);

      await poolAB.addObservation(500111);
      await time.increaseTo((await time.latest()) + 2);

      console.log("tick:", (await poolAB.slot0()).tick);

      ans = await oracle.getPriceOfTokenInToken(
        [B_TOKEN, A_TOKEN, B_TOKEN],
        [FeeAmount.MEDIUM, FeeAmount.MEDIUM],
        10000,
        5
      );
      console.log("aft observation:", ans[0]);

      ans = await oracle.getPriceOfTokenInToken([B_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 10000, PERIOD);
      console.log("BA: ", ans[0]);

      ans = await oracle.getPriceOfTokenInToken([A_TOKEN, B_TOKEN], [FeeAmount.MEDIUM], 10000, PERIOD);
      console.log("AB: ", ans[0]);

      console.log("1 1: ", encodePriceSqrt(1, 1));
      console.log("2 4: ", encodePriceSqrt(2, 4));
      console.log("5 1: ", encodePriceSqrt(5, 1));
    });

    /*
    it("should correctly get complex price", async () => {
      await createPools();

      await oracle.addPaths([A_C_PATH]);

      const firstTime = await time.latest();

      await time.increaseTo(firstTime + 10);

      const pair = <UniswapV2PairMock>await ethers.getContractAt("UniswapV2PairMock", A_C_PAIR);

      await pair.swap(wei("0.85"), 0);

      await time.increaseTo(firstTime + 20);

      let response = await oracle.getPrice(A_TOKEN, 10);

      expect(response[0]).to.equal("35");
      expect(response[1]).to.equal(C_TOKEN);
    });
*/

    it("should not get price if there is no path", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN], [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: invalid path"
      );
    });

    it("should not get price if there wrong amount of fees or tokens", async () => {
      await expect(oracle.getPriceOfTokenInToken(C_A_C_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: path/fee lengths do not match"
      );
    });

    it("should not get price if there is no pool", async () => {
      await expect(oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist"
      );
    });

    it("should not get price if there is 0 period", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);
      await expect(oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, 0)).to.be.revertedWith(
        "TickHelper: period can't be 0"
      );
    });

    it("should not get price if period larger than current timestamp", async () => {
      await expect(
        oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, (await time.latest()) + 10)
      ).to.be.revertedWith("UniswapV3Oracle: period larger than current timestamp");
    });

    it("should return if oldest observation is on current block", async () => {
      pool = await createPools(A_TOKEN, C_TOKEN);

      await pool.initialize(encodePriceSqrt(1, 1));

      await expect(oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, PERIOD)).to.be.revertedWith(
        "UniswapV3Oracle: the oldest observation is on current block"
      );
    });
  });
});
