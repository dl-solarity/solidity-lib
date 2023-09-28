const { assert } = require("chai");
const { toBN, wei } = require("../../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const ERC20Mock = artifacts.require("ERC20Mock");
const DecimalsConverterMock = artifacts.require("DecimalsConverterMock");

ERC20Mock.numberFormat = "BigNumber";
DecimalsConverterMock.numberFormat = "BigNumber";

describe("DecimalsConverter", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await DecimalsConverterMock.new();
  });

  describe("decimals", () => {
    it("should return correct decimals", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 18);
      const token2 = await ERC20Mock.new("MK2", "MK2", 3);

      assert.equal(await mock.decimals(token1.address), 18);
      assert.equal(await mock.decimals(token2.address), 3);
    });
  });

  describe("convert", () => {
    it("should convert", async () => {
      assert.equal((await mock.convert(wei("1"), 18, 6)).toFixed(), wei("1", 6));
      assert.equal((await mock.convert(wei("1", 6), 6, 18)).toFixed(), wei("1"));
      assert.equal((await mock.convert(wei("1", 6), 18, 18)).toFixed(), wei("1", 6));
    });

    it("should convert tokens", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 18);
      const token2 = await ERC20Mock.new("MK2", "MK2", 3);

      assert.equal((await mock.convertTokens(wei("1"), token1.address, token2.address)).toFixed(), wei("1", 3));
      assert.equal((await mock.convertTokens(wei("1", 3), token2.address, token1.address)).toFixed(), wei("1"));
    });
  });

  describe("convert tokens safe", () => {
    it("should correctly convert tokens", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 6);
      const token2 = await ERC20Mock.new("MK2", "MK2", 9);

      assert.equal((await mock.convertTokensSafe(wei("1", 6), token1.address, token2.address)).toFixed(), wei("1", 9));
      assert.equal((await mock.convertTokensSafe(wei("1", 9), token2.address, token1.address)).toFixed(), wei("1", 6));
    });

    it("should get exception if the result of conversion is zero", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 18);
      const token2 = await ERC20Mock.new("MK2", "MK2", 3);

      const reason = "DecimalsConverter: conversion failed";

      await truffleAssert.reverts(mock.convertTokensSafe(wei("1", 3), token1.address, token2.address), reason);
    });
  });

  describe("to18", () => {
    it("should convert to 18", async () => {
      assert.equal((await mock.to18(wei("1", 6), 6)).toFixed(), wei("1"));
      assert.equal((await mock.to18(wei("1", 8), 8)).toFixed(), wei("1"));
      assert.equal((await mock.to18(wei("1", 6), 8)).toFixed(), wei("1", 16));
      assert.equal((await mock.to18(wei("1", 30), 30)).toFixed(), wei("1"));
    });

    it("should convert from token decimals to 18", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 6);
      assert.equal((await mock.tokenTo18(wei("1", 6), token1.address)).toFixed(), wei("1"));

      const token2 = await ERC20Mock.new("MK2", "MK2", 6);
      assert.equal((await mock.tokenTo18(wei("1", 8), token2.address)).toFixed(), wei("1", 20));

      const token3 = await ERC20Mock.new("MK3", "MK3", 18);
      assert.equal((await mock.tokenTo18(wei("1", 6), token3.address)).toFixed(), wei("1", 6));

      const token4 = await ERC20Mock.new("MK4", "MK4", 30);
      assert.equal((await mock.tokenTo18(wei("1", 30), token4.address)).toFixed(), wei("1"));
    });
  });

  describe("to18Safe", () => {
    it("should correctly convert to 18", async () => {
      assert.equal((await mock.to18Safe(wei("1", 6), 6)).toFixed(), wei("1"));
      assert.equal((await mock.to18Safe(wei("1", 8), 8)).toFixed(), wei("1"));
    });

    it("should correctly convert from token decimals to 18", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 6);
      assert.equal((await mock.tokenTo18Safe(wei("1", 6), token1.address)).toFixed(), wei("1"));

      const token2 = await ERC20Mock.new("MK2", "MK2", 8);
      assert.equal((await mock.tokenTo18Safe(wei("1", 8), token2.address)).toFixed(), wei("1"));
    });

    it("should get exception if the result of conversion is zero", async () => {
      const reason = "DecimalsConverter: conversion failed";

      await truffleAssert.reverts(mock.to18Safe(wei("1", 11), 30), reason);
    });
  });

  describe("from18", () => {
    it("should convert from 18", async () => {
      assert.equal((await mock.from18(wei("1"), 6)).toFixed(), wei("1", 6));
      assert.equal((await mock.from18(wei("1"), 8)).toFixed(), wei("1", 8));
      assert.equal((await mock.from18(wei("1", 16), 8)).toFixed(), wei("1", 6));
      assert.equal((await mock.from18(wei("1", 5), 8)).toFixed(), "0");
      assert.equal((await mock.from18(wei("1"), 30)).toFixed(), wei("1", 30));
    });

    it("should convert from 18 to token to token decimals", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 6);
      assert.equal((await mock.tokenFrom18(wei("1"), token1.address)).toFixed(), wei("1", 6));

      const token2 = await ERC20Mock.new("MK2", "MK2", 15);
      assert.equal((await mock.tokenFrom18(wei("1", 12), token2.address)).toFixed(), wei("1", 9));

      const token3 = await ERC20Mock.new("MK3", "MK3", 18);
      assert.equal((await mock.tokenFrom18(wei("1", 6), token3.address)).toFixed(), wei("1", 6));

      const token4 = await ERC20Mock.new("MK4", "MK4", 25);
      assert.equal((await mock.tokenFrom18(wei("1", 20), token4.address)).toFixed(), wei("1", 27));
    });
  });

  describe("from18Safe", () => {
    it("should correctly convert from 18", async () => {
      assert.equal((await mock.from18Safe(wei("1"), 6)).toFixed(), wei("1", 6));
      assert.equal((await mock.from18Safe(wei("1"), 8)).toFixed(), wei("1", 8));
    });

    it("should correctly convert from 18 to token decimals", async () => {
      const token1 = await ERC20Mock.new("MK1", "MK1", 6);
      assert.equal((await mock.tokenFrom18Safe(wei("1"), token1.address)).toFixed(), wei("1", 6));

      const token2 = await ERC20Mock.new("MK2", "MK2", 15);
      assert.equal((await mock.tokenFrom18Safe(wei("1", 12), token2.address)).toFixed(), wei("1", 9));
    });

    it("should get exception if the result of conversion is zero", async () => {
      const reason = "DecimalsConverter: conversion failed";

      await truffleAssert.reverts(mock.from18Safe(wei("1", 6), 6), reason);
    });
  });

  describe("round18", () => {
    it("should round 18", async () => {
      assert.equal((await mock.round18(wei("1"), 18)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1"), 6)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1"), 30)).toFixed(), wei("1"));
      assert.equal((await mock.round18(wei("1", 7), 7)).toFixed(), "0");

      const badNum1 = toBN(wei("1")).plus("123").toFixed();
      const badNum2 = toBN(wei("1")).plus(wei("1", 7)).plus("123").toFixed();

      assert.equal((await mock.round18(badNum1, 4)).toFixed(), wei("1"));
      assert.equal((await mock.round18(badNum2, 12)).toFixed(), toBN(wei("1")).plus(wei("1", 7)).toFixed());
    });
  });

  describe("round18Safe", () => {
    it("should get exception if the result of conversion is zero", async () => {
      const reason = "DecimalsConverter: conversion failed";

      await truffleAssert.reverts(mock.round18Safe(wei("1", 6), 6), reason);
    });
  });
});
