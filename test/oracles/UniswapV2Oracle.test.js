const { assert } = require("chai");
const truffleAssert = require("truffle-assertions");
const { toBN, wei } = require("../../scripts/utils/utils");
const { setTime, getCurrentBlockTime } = require("../helpers/block-helper");

const Oracle = artifacts.require("UniswapV2OracleMock");
const UniswapV2PairMock = artifacts.require("UniswapV2PairMock");
const UniswapV2FactoryMock = artifacts.require("UniswapV2FactoryMock");

Oracle.numberFormat = "BigNumber";
UniswapV2PairMock.numberFormat = "BigNumber";
UniswapV2FactoryMock.numberFormat = "BigNumber";

describe("UniswapV2Oracle", () => {
  const ORACLE_TIME_WINDOW = 1;

  const A_TOKEN = "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa";
  const B_TOKEN = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
  const C_TOKEN = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";
  const A_C_PATH = [A_TOKEN, C_TOKEN];
  const C_A_C_PATH = [C_TOKEN, A_TOKEN, C_TOKEN];
  const B_A_C_PATH = [B_TOKEN, A_TOKEN, C_TOKEN];

  let oracle;
  let uniswapV2Factory;
  let A_C_PAIR;
  let A_B_PAIR;

  beforeEach("setup", async () => {
    uniswapV2Factory = await UniswapV2FactoryMock.new();
    oracle = await Oracle.new();

    await oracle.__OracleV2Mock_init(uniswapV2Factory.address, ORACLE_TIME_WINDOW);
  });

  async function createPairs() {
    await uniswapV2Factory.createPair(A_TOKEN, C_TOKEN);
    await uniswapV2Factory.createPair(A_TOKEN, B_TOKEN);

    A_C_PAIR = await uniswapV2Factory.getPair(A_TOKEN, C_TOKEN);
    A_B_PAIR = await uniswapV2Factory.getPair(A_TOKEN, B_TOKEN);
  }

  describe("init", () => {
    it("should set oracle correctly", async () => {
      assert.equal(await oracle.uniswapV2Factory(), uniswapV2Factory.address);
      assert.equal(await oracle.timeWindow(), ORACLE_TIME_WINDOW);
    });

    it("should not initialize twice", async () => {
      await truffleAssert.reverts(
        oracle.mockInit(uniswapV2Factory.address, ORACLE_TIME_WINDOW),
        "Initializable: contract is not initializing"
      );
      await truffleAssert.reverts(
        oracle.__OracleV2Mock_init(uniswapV2Factory.address, ORACLE_TIME_WINDOW),
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("set", () => {
    it("should set timewindow correctly", async () => {
      await oracle.setTimeWindow(20);

      assert.equal(await oracle.timeWindow(), 20);
    });

    it("should add paths correctly", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH, B_A_C_PATH]);

      assert.deepEqual(await oracle.getPath(A_TOKEN), A_C_PATH);
      assert.deepEqual(await oracle.getPath(B_TOKEN), B_A_C_PATH);

      assert.deepEqual(await oracle.getPairs(), [A_C_PAIR, A_B_PAIR]);
    });

    it("should not allow to set path with length < 2", async () => {
      await truffleAssert.reverts(oracle.addPaths([[C_TOKEN]]), "UniswapV2Oracle: path must be longer than 2");
    });

    it("should not allow to set path with non-existent pairs", async () => {
      await truffleAssert.reverts(oracle.addPaths([A_C_PATH]), "UniswapV2Oracle: uniswap pair doesn't exist");
    });

    it("should not add same path twice", async () => {
      await createPairs();

      await truffleAssert.reverts(oracle.addPaths([A_C_PATH, A_C_PATH]), "UniswapV2Oracle: path already registered");
    });
  });

  describe("remove", () => {
    it("should remove paths correctly", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH]);
      await oracle.addPaths([B_A_C_PATH]);
      await oracle.addPaths([C_A_C_PATH]);

      await oracle.removePaths([A_TOKEN]);

      assert.deepEqual(await oracle.getPath(A_TOKEN), []);
      assert.deepEqual(await oracle.getPairs(), [A_C_PAIR, A_B_PAIR]);

      await oracle.removePaths([B_TOKEN, B_TOKEN]);

      assert.deepEqual(await oracle.getPath(B_TOKEN), []);
      assert.deepEqual(await oracle.getPairs(), [A_C_PAIR]);

      await oracle.removePaths([C_TOKEN]);

      assert.deepEqual(await oracle.getPath(C_TOKEN), []);
      assert.deepEqual(await oracle.getPairs(), []);
    });
  });

  describe("update", () => {
    it("should update price correctly", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH]);

      let rounds = await oracle.getPairRounds(A_C_PAIR);
      let pairInfo = await oracle.getPairInfo(A_C_PAIR, 0);

      assert.equal(rounds, 1);
      assert.equal(pairInfo[2].toFixed(), toBN(await getCurrentBlockTime()).mod(2 ** 32));

      await oracle.updatePrices();

      rounds = await oracle.getPairRounds(A_C_PAIR);

      assert.equal(rounds, 2);
    });

    it("should not update if block is the same or later", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH]);

      await oracle.doubleUpdatePrice();

      let rounds = await oracle.getPairRounds(A_C_PAIR);

      assert.equal(rounds, 2);
    });
  });

  describe("getPrice", () => {
    it("should correctly get price", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH]);

      await oracle.updatePrices();

      let response = await oracle.getPrice(A_TOKEN, 10);

      assert.equal(response[0].toFixed(), 10);
      assert.equal(response[1], C_TOKEN);
    });

    it("should correctly get complex price", async () => {
      await createPairs();

      await oracle.addPaths([A_C_PATH]);

      const firstTime = await getCurrentBlockTime();

      await setTime(firstTime + 10);

      const pair = await UniswapV2PairMock.at(A_C_PAIR);

      await pair.swap(wei("0.85"), 0);

      await setTime(firstTime + 20);

      let response = await oracle.getPrice(A_TOKEN, 10);

      assert.equal(response[0].toFixed(), "35");
      assert.equal(response[1], C_TOKEN);
    });

    it("should return 0 price", async () => {
      await createPairs();

      await oracle.addPaths([B_A_C_PATH]);

      const pair = await UniswapV2PairMock.at(A_B_PAIR);

      await pair.swap(wei("1"), 0);

      let response = await oracle.getPrice(B_TOKEN, 0);

      assert.equal(response[0].toFixed(), "0");
      assert.equal(response[1], C_TOKEN);
    });

    it("should not get price if there is no path", async () => {
      await truffleAssert.reverts(oracle.getPrice(A_TOKEN, 10), "UniswapV2Oracle: invalid path");
    });
  });
});
