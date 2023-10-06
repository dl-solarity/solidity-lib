import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { PriorityQueueMock } from "@ethers-v6";

describe("PriorityQueue", () => {
  const reverter = new Reverter();

  let mock: PriorityQueueMock;

  before("setup", async () => {
    const PriorityQueueMock = await ethers.getContractFactory("PriorityQueueMock");
    mock = await PriorityQueueMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("add()", () => {
    describe("uint", () => {
      it("should add several elements", async () => {
        expect(await mock.lengthUint()).to.equal(0n);

        await mock.addUint(1, 1);
        await mock.addUint(2, 2);
        await mock.addUint(3, 3);
        await mock.addUint(4, 4);
        await mock.addUint(5, 5);

        expect(await mock.lengthUint()).to.equal(5n);
        expect(await mock.topValueUint()).to.equal(5n);
        expect(await mock.topUint()).to.equal([5n, 5n]);

        expect(await mock.valuesUint()).to.equal([5n, 4n, 2n, 1n, 3n]);
        expect(await mock.elementsUint()).to.equal([
          [5n, 4n, 2n, 1n, 3n],
          [5n, 4n, 2n, 1n, 3n],
        ]);
      });

      it("should add elements with the same priority", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 1);
        await mock.addUint(3, 1);

        expect(await mock.topValueUint()).to.equal(1n);
      });

      it("should add element with the same value", async () => {
        await mock.addUint(1, 3);
        await mock.addUint(1, 2);
        await mock.addUint(1, 1);

        expect(await mock.topValueUint()).to.equal(1n);
        expect(await mock.topUint()).to.equal([1n, 3n]);
      });
    });

    describe("bytes32", () => {
      it("should add several elements", async () => {
        await mock.addBytes32(ethers.keccak256("0"), 1);
        await mock.addBytes32(ethers.keccak256("1"), 2);

        expect(await mock.lengthBytes32()).to.equal(2n);
        expect(await mock.topValueBytes32()).to.equal(ethers.keccak256("1"));
        expect(await mock.topBytes32()).to.equal([ethers.keccak256("1"), 2n]);

        expect(await mock.valuesBytes32()).to.equal([ethers.keccak256("1"), ethers.keccak256("0")]);
        expect(await mock.elementsBytes32()).to.equal([
          [ethers.keccak256("1"), ethers.keccak256("0")],
          [2n, 1n],
        ]);
      });
    });

    describe("address", () => {
      it("should add several elements", async () => {
        const [FIRST, SECOND] = await ethers.getSigners();

        await mock.addAddress(FIRST, 1);
        await mock.addAddress(SECOND, 2);

        expect(await mock.lengthAddress()).to.equal(2n);
        expect(await mock.topValueAddress()).to.equal(SECOND);
        expect(await mock.topAddress()).to.equal([SECOND, 2n]);

        expect(await mock.valuesAddress()).to.equal([SECOND, FIRST]);
        expect(await mock.elementsAddress()).to.equal([
          [SECOND, FIRST],
          [2n, 1n],
        ]);
      });
    });
  });

  describe("remove()", async () => {
    describe("uint", () => {
      it("should add and remove the top elements", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 2);
        await mock.addUint(3, 3);
        await mock.addUint(4, 4);
        await mock.addUint(5, 5);

        expect(await mock.lengthUint()).to.equal(5n);
        expect(await mock.topValueUint()).to.equal(5n);

        await mock.removeTopUint();

        expect(await mock.lengthUint()).to.equal(4n);
        expect(await mock.topValueUint()).to.equal(4n);

        await mock.removeTopUint();

        expect(await mock.lengthUint()).to.equal(3n);
        expect(await mock.topValueUint()).to.equal(3n);
      });

      it("should remove then add new elements", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 2);
        await mock.addUint(3, 3);

        await mock.removeTopUint();
        await mock.removeTopUint();

        expect(await mock.lengthUint()).to.equal(1n);
        expect(await mock.topValueUint()).to.equal(1n);

        await mock.addUint(3, 3);

        expect(await mock.lengthUint()).to.equal(2n);
        expect(await mock.topValueUint()).to.equal(3n);
      });

      it("should remove then add new elements (2)", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 8);
        await mock.addUint(3, 10);
        await mock.addUint(4, 12);
        await mock.addUint(5, 7);

        await mock.removeTopUint();
        await mock.removeTopUint();

        expect(await mock.topValueUint()).to.equal(2n);

        await mock.addUint(3, 9);

        expect(await mock.topValueUint()).to.equal(3n);
      });

      it("should not remove elements from an empty queue", async () => {
        await expect(mock.topValueUint()).to.be.revertedWith("PriorityQueue: empty queue");
        await expect(mock.topUint()).to.be.revertedWith("PriorityQueue: empty queue");
        await expect(mock.removeTopUint()).to.be.revertedWith("PriorityQueue: empty queue");
      });
    });

    describe("bytes32", () => {
      it("should add and remove elements", async () => {
        await mock.addBytes32(ethers.keccak256("0"), 1);
        await mock.addBytes32(ethers.keccak256("1"), 2);
        await mock.addBytes32(ethers.keccak256("2"), 3);

        await mock.removeTopBytes32();
        await mock.removeTopBytes32();

        expect(await mock.lengthBytes32()).to.equal(1n);
        expect(await mock.topValueBytes32()).to.equal(ethers.keccak256("0"));
      });
    });

    describe("address", () => {
      it("should add and remove elements", async () => {
        const [FIRST, SECOND, THIRD] = await ethers.getSigners();

        await mock.addAddress(FIRST, 1);
        await mock.addAddress(SECOND, 2);
        await mock.addAddress(THIRD, 3);

        await mock.removeTopAddress();
        await mock.removeTopAddress();

        expect(await mock.lengthAddress()).to.equal(1n);
        expect(await mock.topValueAddress()).to.equal(FIRST);
      });
    });
  });
});
