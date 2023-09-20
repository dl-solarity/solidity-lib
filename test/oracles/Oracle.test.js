const { assert } = require("chai");
const truffleAssert = require("truffle-assertions");
const { time } = require("@openzeppelin/test-helpers");
const { ZERO_ADDR } = require("../../scripts/utils/constants");

const Oracle = artifacts.require("OracleMock");
const UniswapV2FactoryMock = artifacts.require("UniswapV2FactoryMock");

const ORACLE_TIME_WINDOW = 1;
const WPLS = "0xA1077a294dDE1B09bB078844df40758a5D0f9a27";
const PLSX = "0x95B303987A60C71504D99Aa1b13B4DA07b0790ab";
const DAI = "0xefD766cCb38EaF1dfd701853BFCe31359239F305";
const WPLS_DAI_PATH = [WPLS, DAI];
const PLSX_WPLS_DAI_PATH = [PLSX, WPLS, DAI];

describe("Oracle", () => {
  let oracle;
  let factoryAddress;
  let uniswapV2Factory;
  let WPLS_DAI;
  let WPLS_PLSX;

  beforeEach("setup", async () => {
    uniswapV2Factory = await UniswapV2FactoryMock.new();
    factoryAddress = uniswapV2Factory.address;
    oracle = await Oracle.new();
    await oracle.__OracleMock_init(factoryAddress, ORACLE_TIME_WINDOW);
  });

  async function createPairs() {
    await uniswapV2Factory.createPair(WPLS, DAI);
    await uniswapV2Factory.createPair(WPLS, PLSX);

    WPLS_DAI = await uniswapV2Factory.getPair(WPLS, DAI);
    WPLS_PLSX = await uniswapV2Factory.getPair(WPLS, PLSX);
  }

  describe("#init", () => {
    it("should set oracle correctly", async () => {
      assert.equal(await oracle.uniswapV2Factory(), factoryAddress);
      assert.equal(await oracle.timeWindow(), ORACLE_TIME_WINDOW);
    });

    it("should not initialize twice", async () => {
      await truffleAssert.reverts(
        oracle.mockInit(factoryAddress, ORACLE_TIME_WINDOW),
        "Initializable: contract is not initializing"
      );
      await truffleAssert.reverts(
        oracle.__OracleMock_init(factoryAddress, ORACLE_TIME_WINDOW),
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("#setter", () => {
    it("should set timewindow correctly", async () => {
      await oracle.setTimeWindow(20);

      assert.equal(await oracle.timeWindow(), 20);
    });

    it("should set path correctly", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH, PLSX_WPLS_DAI_PATH]);

      assert.deepEqual(await oracle.getPath(WPLS), WPLS_DAI_PATH);
      assert.deepEqual(await oracle.getPath(PLSX), PLSX_WPLS_DAI_PATH);

      assert.equal(await oracle.getCounter(WPLS_DAI), 2);
    });

    it("should add pairs with path correctly", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH]);

      assert.equal(Number(await oracle.getCounter(WPLS_DAI)), 1);
      assert.equal(await oracle.ifPairRegistered(WPLS_DAI), true);
    });

    it("should not allow to set path which length is < 2", async () => {
      await truffleAssert.reverts(oracle.addPaths([[DAI]]), "Oracle: path must be longer than 2");
    });

    it("should not allow to set path with non-existent pairs", async () => {
      await truffleAssert.reverts(oracle.addPaths([WPLS_DAI_PATH]), "Oracle: uniswap pair doesn't exist");
    });
  });

  describe("#remove", () => {
    it("should remove paths correctly", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH]);
      await oracle.addPaths([PLSX_WPLS_DAI_PATH]);

      await oracle.removePaths([WPLS]);
      assert.deepEqual(await oracle.getPath(WPLS), []);
      assert.equal(await oracle.getCounter(WPLS_DAI), 1);

      await oracle.removePaths([PLSX]);
      assert.deepEqual(await oracle.getPath(PLSX), []);
      assert.equal(await oracle.getCounter(WPLS_DAI), 0);
      assert.equal(await oracle.getCounter(WPLS_PLSX), 0);
    });

    it("should not decrement pair counter if counter is 0", async () => {
      await createPairs();

      await oracle.decrementCounter(WPLS_DAI);

      assert.equal(await oracle.getCounter(WPLS_DAI), 0);
    });
  });

  describe("#update", () => {
    it("should update price correctly", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH]);

      await oracle.updatePrices();

      let lenghts = await oracle.getPairInfosLength(WPLS_DAI);

      assert.equal(Number(lenghts[0]), 2);
      assert.equal(Number(lenghts[1]), 2);
      assert.equal(Number(lenghts[2]), 2);
    });

    it("should not update if block is the same or later", async () => {
      await createPairs();
      await oracle.addPaths([WPLS_DAI_PATH]);
      let latest = await time.latest();
      await oracle.setTimestamp(WPLS_DAI, latest + 10);

      await oracle.updatePrices(); //should not update

      await time.increase(time.duration.seconds(1));
      let lenghts = await oracle.getPairInfosLength(WPLS_DAI);
      assert.equal(Number(lenghts[0]), 1);
    });
  });

  describe("#getPrice", () => {
    it("should correctly get price", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH]);

      await oracle.updatePrices();

      await time.increase(time.duration.seconds(1));

      let response = await oracle.getPrice(WPLS, 10);

      assert.equal(response[1], DAI);
      assert.equal(Number(response[0]), 20);
    });

    it("should not get price if there is no path", async () => {
      await truffleAssert.reverts(oracle.getPrice(WPLS, 10), "Oracle: invalid path");
    });

    it("should correctly return 0 from getPrice when blockTimestamps.length is 0", async () => {
      await createPairs();
      await oracle.addPaths([WPLS_DAI_PATH]);

      await oracle.setEmptyTimestamp(WPLS_DAI);

      let response = await oracle.getPrice(WPLS, 10);

      assert.equal(response[1], DAI);
      assert.equal(Number(response[0]), 0);
    });
  });

  describe("#_getPrice (internal)", () => {
    it("should correctly return price if another expectedToken", async () => {
      await createPairs();
      await oracle.addPaths([WPLS_DAI_PATH]);

      await oracle.updatePrices();

      await time.increase(time.duration.seconds(1));
      assert.equal(Number(await oracle.getPriceInternal(WPLS_DAI, WPLS)), 2);
    });

    it("should correctly return price if index is 0", async () => {
      await createPairs();
      await oracle.addPaths([WPLS_DAI_PATH]);

      await oracle.setTimeWindow(await time.latest());

      assert.equal(Number(await oracle.getPriceInternal(WPLS_DAI, DAI)), 0);
    });

    it("should not work when blockTimestamp doesn't change", async () => {
      await createPairs();

      await oracle.addPaths([WPLS_DAI_PATH]);

      await truffleAssert.reverts(oracle.getPriceInternal(WPLS_DAI, DAI), "Oracle: blockTimestamp doesn't change");
    });

    it("should correctly return 0 from _getPrice when blockTimestamps.length is 0", async () => {
      assert.equal(await oracle.getPriceInternal(ZERO_ADDR, DAI), 0);
    });
  });
});
