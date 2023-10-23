import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";

import { UniswapV3OracleMock, UniswapV3FactoryMock } from "@ethers-v6";

describe.only("UniswapV3Oracle", () => {
  const reverter = new Reverter();

  const ORACLE_TIME_WINDOW = 1;

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
  let A_C_PAIR: string;
  let A_B_PAIR: string;

  before("setup", async () => {
    const UniswapV3FactoryMock = await ethers.getContractFactory("UniswapV3FactoryMock");
    const Oracle = await ethers.getContractFactory("UniswapV3OracleMock");

    uniswapV3Factory = await UniswapV3FactoryMock.deploy();
    oracle = await Oracle.deploy();

    await oracle.__OracleV3Mock_init(await uniswapV3Factory.getAddress());

    await reverter.snapshot();
  });

  async function createPools() {
    await uniswapV3Factory.createPool(A_TOKEN, C_TOKEN, FeeAmount.MEDIUM);
    await uniswapV3Factory.createPool(A_TOKEN, B_TOKEN, FeeAmount.MEDIUM);
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
      await createPools();

      //доб ликву?
      expect(await oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, 2)).to.equal(0);
    });

    it("should correctly get price if in path same tokens", async () => {
      await createPools();

      expect(await oracle.getPriceOfTokenInToken([A_TOKEN, A_TOKEN], [FeeAmount.MEDIUM], 5, 2)).to.equal(5);
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

    it("should return 0 price", async () => {
      await createPools();

      await oracle.addPaths([B_A_C_PATH]);

      const pair = <UniswapV2PairMock>await ethers.getContractAt("UniswapV2PairMock", A_C_PAIR);

      await pair.swap(wei("1"), 0);

      let response = await oracle.getPrice(B_TOKEN, 0);

      expect(response[0]).to.equal("0");
      expect(response[1]).to.equal(C_TOKEN);
    });*/

    it("should not get price if there is no path", async () => {
      await expect(oracle.getPriceOfTokenInToken([A_TOKEN], [FeeAmount.MEDIUM], 10, 2)).to.be.revertedWith(
        "UniswapV3Oracle: invalid path"
      );
    });

    it("should not get price if there wrong amount of fees or tokens", async () => {
      await expect(oracle.getPriceOfTokenInToken(B_A_C_PATH, [FeeAmount.MEDIUM], 10, 2)).to.be.revertedWith(
        "UniswapV3Oracle: path/fee lengths do not match"
      );
    });

    it("should not get price if there is no pool", async () => {
      await expect(oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, 2)).to.be.revertedWith(
        "UniswapV3Oracle: such pool doesn't exist"
      );
    });

    it("should not get price if there is no pool", async () => {
      await createPools();
      await expect(oracle.getPriceOfTokenInToken(A_C_PATH, [FeeAmount.MEDIUM], 10, 0)).to.be.revertedWith(
        "UniswapV3Oracle: time window can't be 0"
      );
    });
  });
});
