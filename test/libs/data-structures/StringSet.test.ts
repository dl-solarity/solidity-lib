import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { StringSetMock } from "@ethers-v6";

describe("StringSet", () => {
  const reverter = new Reverter();

  let mock: StringSetMock;

  before("setup", async () => {
    const StringSetMock = await ethers.getContractFactory("StringSetMock");
    mock = await StringSetMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("add()", () => {
    it("should add different strings twice", async () => {
      let expected1 = "test1";
      let expected2 = "test2";

      await mock.add(expected1);
      await mock.add(expected2);

      let set = await mock.getSet();

      expect(set.length).to.equal(2n);
      expect(set[0]).to.equal(expected1);
      expect(set[1]).to.equal(expected2);
    });

    it("should add empty string", async () => {
      let expected = "";

      await mock.add(expected);

      let set = await mock.getSet();

      expect(set.length).to.equal(1n);
      expect(set[0]).to.equal(expected);
    });

    it("should add same string twice", async () => {
      let expected = "test";

      await mock.add(expected);
      await mock.add(expected);

      let set = await mock.getSet();

      expect(set.length).to.equal(1n);
      expect(set[0]).to.equal(expected);
    });
  });

  describe("remove()", () => {
    it("should remove string", async () => {
      let expected = "test";

      await mock.add(expected);
      await mock.remove(expected);

      let set = await mock.getSet();

      expect(set.length).to.equal(0n);
    });

    it("should call remove at empty set", async () => {
      await mock.remove("test");
    });

    it("should remove non-existent string", async () => {
      let expected = "test";

      await mock.add(expected);
      await mock.remove(expected + "1");

      let set = await mock.getSet();

      expect(set.length).to.equal(1n);
      expect(set[0]).to.equal(expected);
    });

    it("should remove from middle", async () => {
      let expected1 = "test1";
      let expected2 = "test2";
      let expected3 = "test3";

      await mock.add(expected1);
      await mock.add(expected2);
      await mock.add(expected3);
      await mock.remove(expected2);

      let set = await mock.getSet();

      expect(set.length).to.equal(2n);
      expect(set[0]).to.equal(expected1);
      expect(set[1]).to.equal(expected3);
    });
  });

  describe("contains()", () => {
    it("should return true", async () => {
      let expected = "test";

      await mock.add(expected);

      expect(await mock.contains(expected)).to.be.true;
    });

    it("should return false", async () => {
      let expected = "test";

      await mock.add(expected);

      expect(await mock.contains(expected + "1")).to.be.false;
    });
  });

  describe("length()", () => {
    it("should return correct length", async () => {
      let expected = "test";

      expect(await mock.length()).to.equal(0n);

      await mock.add(expected);

      expect(await mock.length()).to.equal(1n);

      await mock.add(expected);

      expect(await mock.length()).to.equal(1n);
    });
  });

  describe("at()", () => {
    it("should correctly return 10 values", async () => {
      let expected = "test";

      for (let i = 0; i < 10; i++) {
        await mock.add(expected + i);
      }

      for (let i = 0; i < 10; i++) {
        expect(await mock.at(i)).to.equal(expected + i);
      }
    });
  });

  describe("values()", () => {
    it("should return all values", async () => {
      let expected = "test";

      for (let i = 0; i < 10; i++) {
        await mock.add(expected + i);
      }

      let values = await mock.values();

      for (let i = 0; i < 10; i++) {
        expect(expected + i).to.equal(values[i]);
      }
    });
  });
});
