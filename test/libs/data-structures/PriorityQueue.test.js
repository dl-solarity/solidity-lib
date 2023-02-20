const { assert } = require("chai");
const { accounts } = require("../../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const PriorityQueueMock = artifacts.require("PriorityQueueMock");

PriorityQueueMock.numberFormat = "BigNumber";

describe("PriorityQueueMock", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await PriorityQueueMock.new();
  });

  describe("add()", () => {
    describe("uint", () => {
      it("should add several elements", async () => {
        assert.equal(await mock.lengthUint(), "0");

        await mock.addUint(1, 1);
        await mock.addUint(2, 2);
        await mock.addUint(3, 3);
        await mock.addUint(4, 4);
        await mock.addUint(5, 5);

        assert.equal(await mock.lengthUint(), "5");
        assert.equal((await mock.topValueUint()).toFixed(), "5");
        assert.deepEqual(
          Object.values(await mock.topUint()).map((e) => e.toFixed()),
          ["5", "5"]
        );

        assert.deepEqual(
          Object.values(await mock.valuesUint()).map((e) => e.toFixed()),
          ["5", "4", "2", "1", "3"]
        );
        assert.deepEqual(
          Object.values(await mock.elementsUint())
            .flat()
            .map((e) => e.toFixed()),
          ["5", "4", "2", "1", "3", "5", "4", "2", "1", "3"]
        );
      });

      it("should add elements with the same priority", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 1);
        await mock.addUint(3, 1);

        assert.equal((await mock.topValueUint()).toFixed(), "1");
      });

      it("should add element with the same value", async () => {
        await mock.addUint(1, 3);
        await mock.addUint(1, 2);
        await mock.addUint(1, 1);

        assert.equal((await mock.topValueUint()).toFixed(), "1");
        assert.deepEqual(
          Object.values(await mock.topUint()).map((e) => e.toFixed()),
          ["1", "3"]
        );
      });
    });

    describe("bytes32", () => {
      it("should add several elements", async () => {
        await mock.addBytes32(web3.utils.keccak256("0"), 1);
        await mock.addBytes32(web3.utils.keccak256("1"), 2);

        assert.equal(await mock.lengthBytes32(), "2");
        assert.equal(await mock.topValueBytes32(), web3.utils.keccak256("1"));

        const value = await mock.topBytes32();

        assert.equal(value[0], web3.utils.keccak256("1"));
        assert.equal(value[1].toFixed(), "2");

        const values = await mock.valuesBytes32();

        assert.deepEqual(values, [web3.utils.keccak256("1"), web3.utils.keccak256("0")]);

        const elements = await mock.elementsBytes32();

        assert.deepEqual(elements[0], [web3.utils.keccak256("1"), web3.utils.keccak256("0")]);
        assert.deepEqual(
          elements[1].map((e) => e.toFixed()),
          ["2", "1"]
        );
      });
    });

    describe("address", () => {
      it("should add several elements", async () => {
        await mock.addAddress(await accounts(0), 1);
        await mock.addAddress(await accounts(1), 2);

        assert.equal(await mock.lengthAddress(), "2");
        assert.equal(await mock.topValueAddress(), await accounts(1));

        const value = await mock.topAddress();

        assert.equal(value[0], await accounts(1));
        assert.equal(value[1].toFixed(), "2");

        const values = await mock.valuesAddress();

        assert.deepEqual(values, [await accounts(1), await accounts(0)]);

        const elements = await mock.elementsAddress();

        assert.deepEqual(elements[0], [await accounts(1), await accounts(0)]);
        assert.deepEqual(
          elements[1].map((e) => e.toFixed()),
          ["2", "1"]
        );
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

        assert.equal(await mock.lengthUint(), "5");
        assert.equal((await mock.topValueUint()).toFixed(), "5");

        await mock.removeTopUint();

        assert.equal(await mock.lengthUint(), "4");
        assert.equal((await mock.topValueUint()).toFixed(), "4");

        await mock.removeTopUint();

        assert.equal(await mock.lengthUint(), "3");
        assert.equal((await mock.topValueUint()).toFixed(), "3");
      });

      it("should remove then add new elements", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 2);
        await mock.addUint(3, 3);

        await mock.removeTopUint();
        await mock.removeTopUint();

        assert.equal(await mock.lengthUint(), "1");
        assert.equal((await mock.topValueUint()).toFixed(), "1");

        await mock.addUint(3, 3);

        assert.equal(await mock.lengthUint(), "2");
        assert.equal((await mock.topValueUint()).toFixed(), "3");
      });

      it("should remove then add new elements (2)", async () => {
        await mock.addUint(1, 1);
        await mock.addUint(2, 8);
        await mock.addUint(3, 10);
        await mock.addUint(4, 12);
        await mock.addUint(5, 7);

        await mock.removeTopUint();
        await mock.removeTopUint();

        assert.equal((await mock.topValueUint()).toFixed(), "2");

        await mock.addUint(3, 9);

        assert.equal((await mock.topValueUint()).toFixed(), "3");
      });

      it("should not remove elements from an empty queue", async () => {
        await truffleAssert.reverts(mock.topValueUint(), "PriorityQueue: empty queue");
        await truffleAssert.reverts(mock.topUint(), "PriorityQueue: empty queue");
        await truffleAssert.reverts(mock.removeTopUint(), "PriorityQueue: empty queue");
      });
    });

    describe("bytes32", () => {
      it("should add and remove elements", async () => {
        await mock.addBytes32(web3.utils.keccak256("0"), 1);
        await mock.addBytes32(web3.utils.keccak256("1"), 2);
        await mock.addBytes32(web3.utils.keccak256("2"), 3);

        await mock.removeTopBytes32();
        await mock.removeTopBytes32();

        assert.equal(await mock.lengthBytes32(), "1");
        assert.equal(await mock.topValueBytes32(), web3.utils.keccak256("0"));
      });
    });

    describe("address", () => {
      it("should add and remove elements", async () => {
        await mock.addAddress(await accounts(0), 1);
        await mock.addAddress(await accounts(1), 2);
        await mock.addAddress(await accounts(2), 3);

        await mock.removeTopAddress();
        await mock.removeTopAddress();

        assert.equal(await mock.lengthAddress(), "1");
        assert.equal(await mock.topValueAddress(), await accounts(0));
      });
    });
  });
});
