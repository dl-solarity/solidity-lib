const { assert } = require("chai");

const PaginatorMock = artifacts.require("PaginatorMock");

PaginatorMock.numberFormat = "BigNumber";

describe("PaginatorMock", () => {
  let mock;

  beforeEach("setup", async () => {
    mock = await PaginatorMock.new();
  });

  describe("uint array, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partUintArr(0, 1);

      assert.equal(arr.length, 0);
    });
  });

  describe("uint array", async () => {
    beforeEach(async () => {
      await mock.pushUint(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partUintArr(0, 0);

      assert.equal(arr.length, 0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partUintArr(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partUintArr(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], 100);
      assert.equal(arr[4], 104);
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partUintArr(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], 100);
      assert.equal(arr[1], 101);
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partUintArr(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], 100);
      assert.equal(arr[4], 104);
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partUintArr(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 102);
      assert.equal(arr[2], 104);
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partUintArr(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], 102);
      assert.equal(arr[1], 103);
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partUintArr(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 102);
      assert.equal(arr[2], 104);
    });
  });

  describe("uint set", async () => {
    beforeEach(async () => {
      await mock.pushUint(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partUintSet(0, 0);

      assert.equal(arr.length, 0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partUintSet(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partUintSet(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], 100);
      assert.equal(arr[4], 104);
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partUintSet(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], 100);
      assert.equal(arr[1], 101);
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partUintSet(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], 100);
      assert.equal(arr[4], 104);
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partUintSet(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 102);
      assert.equal(arr[2], 104);
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partUintSet(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], 102);
      assert.equal(arr[1], 103);
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partUintSet(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], 102);
      assert.equal(arr[2], 104);
    });
  });

  describe("address array, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partAddressArr(0, 1);

      assert.equal(arr.length, 0);
    });
  });

  describe("address array", async () => {
    beforeEach(async () => {
      await mock.pushAddress(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partAddressArr(0, 0);

      assert.equal(arr.length, 0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partAddressArr(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partAddressArr(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partAddressArr(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partAddressArr(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partAddressArr(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partAddressArr(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partAddressArr(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000004");
    });
  });

  describe("bytes, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partBytesArr(0, 1);

      assert.equal(arr.length, 0);
    });

    it("should return empty set", async () => {
      const arr = await mock.partBytesSet(0, 1);

      assert.equal(arr.length, 0);
    });
  });

  describe("bytes array", async () => {
    beforeEach(async () => {
      await mock.pushBytes(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partBytesArr(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partBytesArr(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partBytesArr(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partBytesArr(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partBytesArr(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partBytesArr(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partBytesArr(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });
  });

  describe("bytes set", async () => {
    beforeEach(async () => {
      await mock.pushBytes(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partBytesSet(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partBytesSet(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partBytesSet(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partBytesSet(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partBytesSet(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partBytesSet(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partBytesSet(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000000000000000000000000000004");
    });
  });

  describe("string set", () => {
    beforeEach(async () => {
      await mock.pushString(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partStringSet(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partStringSet(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0");
      assert.equal(arr[4], "4");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partStringSet(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0");
      assert.equal(arr[1], "1");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partStringSet(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0");
      assert.equal(arr[4], "4");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partStringSet(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "2");
      assert.equal(arr[2], "4");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partStringSet(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "2");
      assert.equal(arr[1], "3");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partStringSet(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "2");
      assert.equal(arr[2], "4");
    });
  });

  describe("address set", () => {
    beforeEach(async () => {
      await mock.pushAddress(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partAddressSet(10, 1);

      assert.equal(arr.length, 0);
    });

    it("should return full array", async () => {
      const arr = await mock.partAddressSet(0, 5);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partAddressSet(0, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partAddressSet(0, 1000);

      assert.equal(arr.length, 5);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000000");
      assert.equal(arr[4], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partAddressSet(2, 3);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partAddressSet(2, 2);

      assert.equal(arr.length, 2);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[1], "0x0000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partAddressSet(2, 1000);

      assert.equal(arr.length, 3);
      assert.equal(arr[0], "0x0000000000000000000000000000000000000002");
      assert.equal(arr[2], "0x0000000000000000000000000000000000000004");
    });
  });
});
