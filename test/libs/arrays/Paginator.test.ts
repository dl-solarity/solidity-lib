import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { PaginatorMock } from "@ethers-v6";
import { BigNumberish } from "ethers";

describe("Paginator", () => {
  const reverter = new Reverter();

  let mock: PaginatorMock;

  function encodeBytes(values: BigNumberish[], types: string[] = ["uint256"]) {
    return ethers.AbiCoder.defaultAbiCoder().encode(types, values);
  }

  before("setup", async () => {
    const PaginatorMock = await ethers.getContractFactory("PaginatorMock");
    mock = await PaginatorMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("uint array, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partUintArr(0, 1);

      expect(arr.length).to.equal(0);
    });
  });

  describe("uint array", async () => {
    beforeEach(async () => {
      await mock.pushUint(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partUintArr(0, 0);

      expect(arr.length).to.equal(0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partUintArr(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partUintArr(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(100n);
      expect(arr[4]).to.equal(104n);
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partUintArr(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(100n);
      expect(arr[1]).to.equal(101n);
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partUintArr(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(100n);
      expect(arr[4]).to.equal(104n);
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partUintArr(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(102n);
      expect(arr[2]).to.equal(104n);
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partUintArr(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(102n);
      expect(arr[1]).to.equal(103n);
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partUintArr(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(102n);
      expect(arr[2]).to.equal(104n);
    });
  });

  describe("uint set", async () => {
    beforeEach(async () => {
      await mock.pushUint(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partUintSet(0, 0);

      expect(arr.length).to.equal(0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partUintSet(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partUintSet(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(100n);
      expect(arr[4]).to.equal(104n);
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partUintSet(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(100n);
      expect(arr[1]).to.equal(101n);
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partUintSet(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(100n);
      expect(arr[4]).to.equal(104n);
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partUintSet(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(102n);
      expect(arr[2]).to.equal(104n);
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partUintSet(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(102n);
      expect(arr[1]).to.equal(103n);
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partUintSet(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(102n);
      expect(arr[2]).to.equal(104n);
    });
  });

  describe("address array, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partAddressArr(0, 1);

      expect(arr.length).to.equal(0);
    });
  });

  describe("address array", async () => {
    beforeEach(async () => {
      await mock.pushAddress(5);
    });

    it("should return empty array", async () => {
      const arr = await mock.partAddressArr(0, 0);

      expect(arr.length).to.equal(0);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partAddressArr(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partAddressArr(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partAddressArr(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partAddressArr(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partAddressArr(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partAddressArr(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partAddressArr(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000004");
    });
  });

  describe("bytes32, empty", async () => {
    it("should return empty array", async () => {
      const arr = await mock.partBytes32Arr(0, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return empty set", async () => {
      const arr = await mock.partBytes32Set(0, 1);

      expect(arr.length).to.equal(0);
    });
  });

  describe("bytes32 array", async () => {
    beforeEach(async () => {
      await mock.pushBytes32(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partBytes32Arr(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partBytes32Arr(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partBytes32Arr(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partBytes32Arr(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partBytes32Arr(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partBytes32Arr(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partBytes32Arr(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });
  });

  describe("bytes32 set", async () => {
    beforeEach(async () => {
      await mock.pushBytes32(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partBytes32Set(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partBytes32Set(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partBytes32Set(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partBytes32Set(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partBytes32Set(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partBytes32Set(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partBytes32Set(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000000000000000000000000000004");
    });
  });

  describe("bytes set", () => {
    beforeEach(async () => {
      await mock.pushBytes(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partBytesSet(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partBytesSet(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(encodeBytes(["0"]));
      expect(arr[4]).to.equal(encodeBytes(["4"]));
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partBytesSet(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(encodeBytes(["0"]));
      expect(arr[1]).to.equal(encodeBytes(["1"]));
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partBytesSet(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal(encodeBytes(["0"]));
      expect(arr[4]).to.equal(encodeBytes(["4"]));
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partBytesSet(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(encodeBytes(["2"]));
      expect(arr[2]).to.equal(encodeBytes(["4"]));
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partBytesSet(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal(encodeBytes(["2"]));
      expect(arr[1]).to.equal(encodeBytes(["3"]));
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partBytesSet(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal(encodeBytes(["2"]));
      expect(arr[2]).to.equal(encodeBytes(["4"]));
    });
  });

  describe("string set", () => {
    beforeEach(async () => {
      await mock.pushString(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partStringSet(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partStringSet(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0");
      expect(arr[4]).to.equal("4");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partStringSet(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0");
      expect(arr[1]).to.equal("1");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partStringSet(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0");
      expect(arr[4]).to.equal("4");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partStringSet(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("2");
      expect(arr[2]).to.equal("4");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partStringSet(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("2");
      expect(arr[1]).to.equal("3");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partStringSet(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("2");
      expect(arr[2]).to.equal("4");
    });
  });

  describe("address set", () => {
    beforeEach(async () => {
      await mock.pushAddress(5);
    });

    it("should return empty array if `offset` is bigger then length", async () => {
      const arr = await mock.partAddressSet(10, 1);

      expect(arr.length).to.equal(0);
    });

    it("should return full array", async () => {
      const arr = await mock.partAddressSet(0, 5);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the beginning, part of the array ", async () => {
      const arr = await mock.partAddressSet(0, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000001");
    });

    it("should return from the beginning, full array, length overrun", async () => {
      const arr = await mock.partAddressSet(0, 1000);

      expect(arr.length).to.equal(5);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000000");
      expect(arr[4]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, full array", async () => {
      const arr = await mock.partAddressSet(2, 3);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000004");
    });

    it("should return from the middle part, part of the array", async () => {
      const arr = await mock.partAddressSet(2, 2);

      expect(arr.length).to.equal(2);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[1]).to.equal("0x0000000000000000000000000000000000000003");
    });

    it("should return from the middle part, full array, length overrun", async () => {
      const arr = await mock.partAddressSet(2, 1000);

      expect(arr.length).to.equal(3);
      expect(arr[0]).to.equal("0x0000000000000000000000000000000000000002");
      expect(arr[2]).to.equal("0x0000000000000000000000000000000000000004");
    });
  });
});
