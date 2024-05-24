import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { AvlTreeMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { encodeBytes32String } from "ethers";

describe("AvlTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;
  let USER2: SignerWithAddress;
  let USER3: SignerWithAddress;
  let USER4: SignerWithAddress;
  let USER5: SignerWithAddress;
  let USER6: SignerWithAddress;

  let avlTree: AvlTreeMock;

  before(async () => {
    [USER1, USER2, USER3, USER4, USER5, USER6] = await ethers.getSigners();
    const AvlTreeMock = await ethers.getContractFactory("AvlTreeMock");

    avlTree = await AvlTreeMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  function uintToBytes32Array(uintArray: Array<number>) {
    let bytes32Array = [];

    for (let i = 0; i < uintArray.length; i++) {
      bytes32Array.push(encodeBytes32String(uintArray[i].toString()));
    }

    return bytes32Array;
  }

  describe("Uint Tree", () => {
    describe("insert", () => {
      it("should insert uint values to the uint tree correctly", async () => {
        await avlTree.setUintValueComparatorUint();

        await avlTree.insertUintToUint(1, 4);
        await avlTree.insertUintToUint(2, 12);
        await avlTree.insertUintToUint(3, 1);

        expect(await avlTree.rootUint()).to.equal(1);
        expect(await avlTree.treeSizeUint()).to.equal(3);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([3, 1, 2]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([1, 3, 2]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([3, 2, 1]);

        await avlTree.insertUintToUint(4, 200);
        await avlTree.insertUintToUint(5, 10);
        await avlTree.insertUintToUint(6, 5);

        expect(await avlTree.rootUint()).to.equal(5);
        expect(await avlTree.treeSizeUint()).to.equal(6);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([3, 1, 6, 5, 2, 4]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([5, 1, 3, 6, 2, 4]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([3, 6, 1, 4, 2, 5]);

        await avlTree.insertUintToUint(7, 15);

        expect(await avlTree.rootUint()).to.equal(5);
        expect(await avlTree.treeSizeUint()).to.equal(7);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([3, 1, 6, 5, 2, 7, 4]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([5, 1, 3, 6, 7, 2, 4]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([3, 6, 1, 2, 4, 7, 5]);

        await avlTree.insertUintToUint(8, 2);
        await avlTree.insertUintToUint(9, 3);

        expect(await avlTree.rootUint()).to.equal(5);
        expect(await avlTree.treeSizeUint()).to.equal(9);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([3, 8, 9, 1, 6, 5, 2, 7, 4]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([5, 1, 8, 3, 9, 6, 7, 2, 4]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([3, 9, 8, 6, 1, 2, 4, 7, 5]);
      });

      it("should insert address values to the uint tree correctly", async () => {
        await avlTree.insertAddressToUint(2, USER2);
        await avlTree.insertAddressToUint(6, USER1);
        await avlTree.insertAddressToUint(4, USER2);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(3);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([2, 4, 6]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 2, 6]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([2, 6, 4]);

        await avlTree.insertAddressToUint(1, USER2);
        await avlTree.insertAddressToUint(13, USER4);
        await avlTree.insertAddressToUint(7, USER1);
        await avlTree.insertAddressToUint(5, USER3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(7);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([1, 2, 4, 5, 6, 7, 13]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 2, 1, 7, 6, 5, 13]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([1, 2, 5, 6, 13, 7, 4]);

        await avlTree.insertAddressToUint(9, USER4);
        await avlTree.insertAddressToUint(8, USER4);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(9);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([1, 2, 4, 5, 6, 7, 8, 9, 13]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 2, 1, 7, 6, 5, 9, 8, 13]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([1, 2, 5, 6, 8, 13, 9, 7, 4]);
      });

      it("should insert string values to the uint tree correctly", async () => {
        await avlTree.setUintValueComparatorString();

        await avlTree.insertStringToUint(1, "b");
        await avlTree.insertStringToUint(2, "f");
        await avlTree.insertStringToUint(3, "g");
        await avlTree.insertStringToUint(4, "a");
        await avlTree.insertStringToUint(5, "d");

        expect(await avlTree.rootUint()).to.equal(2);
        expect(await avlTree.treeSizeUint()).to.equal(5);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([4, 1, 5, 2, 3]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([2, 1, 4, 5, 3]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([4, 5, 1, 3, 2]);

        await avlTree.insertStringToUint(6, "e");
        await avlTree.insertStringToUint(7, "c");

        expect(await avlTree.rootUint()).to.equal(5);
        expect(await avlTree.treeSizeUint()).to.equal(7);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([4, 1, 7, 5, 6, 2, 3]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([5, 1, 4, 7, 2, 6, 3]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([4, 7, 1, 6, 3, 2, 5]);
      });

      it("should insert struct values to the uint tree correctly", async () => {
        await avlTree.setUintValueComparatorStruct();

        await avlTree.insertStructToUint(1, await avlTree.valueToBytesStruct(20));
        await avlTree.insertStructToUint(2, await avlTree.valueToBytesStruct(1));
        await avlTree.insertStructToUint(3, await avlTree.valueToBytesStruct(18));

        expect(await avlTree.rootUint()).to.equal(3);
        expect(await avlTree.treeSizeUint()).to.equal(3);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([2, 3, 1]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([3, 2, 1]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([2, 1, 3]);

        await avlTree.insertStructToUint(4, await avlTree.valueToBytesStruct(17));
        await avlTree.insertStructToUint(5, await avlTree.valueToBytesStruct(16));

        expect(await avlTree.rootUint()).to.equal(3);
        expect(await avlTree.treeSizeUint()).to.equal(5);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([2, 5, 4, 3, 1]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([3, 5, 2, 4, 1]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([2, 4, 5, 1, 3]);

        await avlTree.insertStructToUint(6, await avlTree.valueToBytesStruct(2));

        expect(await avlTree.rootUint()).to.equal(5);
        expect(await avlTree.treeSizeUint()).to.equal(6);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([2, 6, 5, 4, 3, 1]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([5, 2, 6, 3, 4, 1]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([6, 2, 4, 1, 3, 5]);
      });

      it("should not allow to insert 0 as key to the uint tree", async () => {
        await expect(avlTree.insertStringToUint(0, "test")).to.be.revertedWith("AvlTree: key is not allowed to be 0");
      });

      it("should not allow to insert node with duplicate key to the uint tree", async () => {
        await avlTree.insertUintToUint(2, 10);
        await expect(avlTree.insertUintToUint(2, 4)).to.be.revertedWith("AvlTree: the node already exists");
      });
    });

    describe("remove", () => {
      it("should remove a node in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 4);
        await avlTree.insertUintToUint(3, 8);
        await avlTree.insertUintToUint(6, 10);
        await avlTree.insertUintToUint(1, 2);
        await avlTree.insertUintToUint(4, 10);
        await avlTree.insertUintToUint(7, 10);
        await avlTree.insertUintToUint(10, 10);

        expect(await avlTree.rootUint()).to.equal(3);
        expect(await avlTree.treeSizeUint()).to.equal(7);

        await avlTree.removeUint(3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(6);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([1, 2, 4, 6, 7, 10]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 2, 1, 7, 6, 10]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([1, 2, 6, 10, 7, 4]);
      });

      it("should remove multiple nodes in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(1, 2);
        await avlTree.insertUintToUint(4, 20);
        await avlTree.insertUintToUint(3, 4);
        await avlTree.insertUintToUint(7, 1);
        await avlTree.insertUintToUint(8, 10);
        await avlTree.insertUintToUint(9, 1);
        await avlTree.insertUintToUint(5, 12);
        await avlTree.insertUintToUint(6, 11);

        await avlTree.removeUint(8);
        await avlTree.removeUint(3);
        await avlTree.removeUint(5);

        expect(await avlTree.rootUint()).to.equal(6);
        expect(await avlTree.treeSizeUint()).to.equal(5);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([1, 4, 6, 7, 9]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([6, 4, 1, 7, 9]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([1, 4, 9, 7, 6]);
      });

      it("should handle removing all the nodes in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 1);
        await avlTree.insertUintToUint(4, 10);
        await avlTree.insertUintToUint(3, 2);
        await avlTree.removeUint(4);
        await avlTree.removeUint(2);
        await avlTree.insertUintToUint(2, 2);
        await avlTree.insertUintToUint(1, 2);
        await avlTree.removeUint(2);
        await avlTree.removeUint(1);
        await avlTree.removeUint(3);

        expect(await avlTree.rootUint()).to.be.equal(0);
        expect(await avlTree.treeSizeUint()).to.be.equal(0);
      });

      it("should not allow to remove a node that doesn't exist in the uint tree", async () => {
        await avlTree.insertUintToUint(1, 10);

        await expect(avlTree.removeUint(2)).to.be.revertedWith("AvlTree: the node doesn't exist");
        await expect(avlTree.removeUint(0)).to.be.revertedWith("AvlTree: key is not allowed to be 0");
      });

      it("should not allow to remove a node twice in the uint tree", async () => {
        await avlTree.insertUintToUint(1, 10);
        await avlTree.insertUintToUint(2, 20);

        await avlTree.removeUint(2);

        await expect(avlTree.removeUint(2)).to.be.revertedWith("AvlTree: the node doesn't exist");
      });

      it("should not allow to remove nodes in the empty uint tree", async () => {
        await expect(avlTree.removeUint(1)).to.be.revertedWith("AvlTree: the node doesn't exist");
      });
    });

    describe("setComparator", () => {
      it("should set a comparator for the uint tree correctly", async () => {
        await avlTree.setUintDescComparator();

        await avlTree.insertUintToUint(2, 3);
        await avlTree.insertUintToUint(4, 10);
        await avlTree.insertUintToUint(1, 4);
        await avlTree.insertUintToUint(6, 4);
        await avlTree.insertUintToUint(3, 200);
        await avlTree.insertUintToUint(5, 1);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(6);
        expect(await avlTree.inOrderTraversalUint()).to.deep.equal([6, 5, 4, 3, 2, 1]);
        expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 6, 5, 2, 3, 1]);
        expect(await avlTree.postOrderTraversalUint()).to.deep.equal([5, 6, 3, 1, 2, 4]);
      });

      it("should not allow to set comparator for the uint tree if the tree is not empty", async () => {
        await avlTree.insertUintToUint(1, 10);

        await expect(avlTree.setUintDescComparator()).to.be.revertedWith("AvlTree: the tree must be empty");
      });
    });

    describe("getters", () => {
      it("should handle searching for the existing key in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 20);
        await avlTree.insertUintToUint(1, 10);

        expect(await avlTree.searchUint(2)).to.be.true;
      });

      it("should handle searching for the non-existing key in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 1);

        expect(await avlTree.searchUint(3)).to.be.false;
      });

      it("should handle searching for the zero key in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 1);

        expect(await avlTree.searchUint(0)).to.be.false;
      });

      it("should get value for the existing node in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(1, 4);
        await avlTree.insertUintToUint(2, 2);

        await avlTree.insertAddressToUint(3, USER1);
        await avlTree.insertAddressToUint(4, USER2);

        await avlTree.insertStringToUint(5, "test1");
        await avlTree.insertStringToUint(6, "test2");

        expect(await avlTree.getUintValueUint(1)).to.equal(4);
        expect(await avlTree.getUintValueUint(2)).to.equal(2);

        expect(await avlTree.getAddressValueUint(3)).to.equal(USER1);
        expect(await avlTree.getAddressValueUint(4)).to.equal(USER2);

        expect(await avlTree.getStringValueUint(5)).to.equal("test1");
        expect(await avlTree.getStringValueUint(6)).to.equal("test2");
      });

      it("should handle getting value for the non-existing node in the uint tree correctly", async () => {
        await expect(avlTree.getUintValueUint(1)).to.be.revertedWith("AvlTree: node with such key doesn't exist");

        await avlTree.insertUintToUint(1, 30);
        await expect(avlTree.getUintValueUint(2)).to.be.revertedWith("AvlTree: node with such key doesn't exist");
        await expect(avlTree.getUintValueUint(0)).to.be.revertedWith("AvlTree: node with such key doesn't exist");
      });

      it("should get minimum node in the uint tree correctly", async () => {
        await avlTree.setUintValueComparatorUint();

        await avlTree.insertUintToUint(4, 10);
        await avlTree.insertUintToUint(5, 4);
        await avlTree.insertUintToUint(1, 200);
        await avlTree.insertUintToUint(2, 6);

        expect(await avlTree.getMinUint()).to.be.equal(5);
      });

      it("should get maximum node in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(4, 100);
        await avlTree.insertUintToUint(5, 4);
        await avlTree.insertUintToUint(8, 80);
        await avlTree.insertUintToUint(1, 6);

        expect(await avlTree.getMaxUint()).to.be.equal(8);
      });

      it("should get the root key in the uint tree correctly", async () => {
        expect(await avlTree.rootUint()).to.be.equal(0);

        await avlTree.insertUintToUint(1, 10);
        await avlTree.insertUintToUint(100, 10);
        await avlTree.insertUintToUint(22, 4);
        await avlTree.insertUintToUint(7, 90);
        await avlTree.insertUintToUint(2, 1);
        await avlTree.insertUintToUint(3, 1);

        expect(await avlTree.rootUint()).to.be.equal(7);
      });

      it("should get the treeSize correctly for the uint tree", async () => {
        expect(await avlTree.treeSizeUint()).to.be.equal(0);

        await avlTree.insertUintToUint(1, 10);
        await avlTree.insertUintToUint(2, 10);
        await avlTree.removeUint(1);
        await avlTree.insertUintToUint(3, 4);
        await avlTree.insertUintToUint(7, 90);

        expect(await avlTree.treeSizeUint()).to.be.equal(3);
      });

      it("should check if custom comparator is set for the uint tree correctly", async () => {
        expect(await avlTree.isCustomComparatorSetUint()).to.be.false;

        await avlTree.setUintValueComparatorUint();

        expect(await avlTree.isCustomComparatorSetUint()).to.be.true;
      });
    });

    it("should handle complex operations on the uint tree", async () => {
      await avlTree.insertUintToUint(2, 10);
      await avlTree.insertUintToUint(3, 1);
      await avlTree.insertUintToUint(10, 18);

      await avlTree.removeUint(3);

      await avlTree.insertUintToUint(4, 20);
      await avlTree.insertUintToUint(5, 10);

      await avlTree.removeUint(2);
      await avlTree.removeUint(10);
      await avlTree.removeUint(4);

      await avlTree.insertUintToUint(4, 7);
      await avlTree.insertUintToUint(1, 20);
      await avlTree.insertUintToUint(2, 10);
      await avlTree.insertUintToUint(20, 20);
      await avlTree.insertUintToUint(111, 10);

      await avlTree.removeUint(20);

      await avlTree.insertUintToUint(16, 20);
      await avlTree.insertUintToUint(17, 100);
      await avlTree.insertUintToUint(18, 20);
      await avlTree.insertUintToUint(19, 250);
      await avlTree.insertUintToUint(20, 4);

      expect(await avlTree.rootUint()).to.equal(4);
      expect(await avlTree.treeSizeUint()).to.equal(10);
      expect(await avlTree.inOrderTraversalUint()).to.deep.equal([1, 2, 4, 5, 16, 17, 18, 19, 20, 111]);
      expect(await avlTree.preOrderTraversalUint()).to.deep.equal([4, 1, 2, 18, 16, 5, 17, 20, 19, 111]);
      expect(await avlTree.postOrderTraversalUint()).to.deep.equal([2, 1, 5, 17, 16, 19, 111, 20, 18, 4]);
    });
  });

  describe("Bytes32 Tree", () => {
    it("should insert nodes to the bytes32 tree correctly", async () => {
      await avlTree.setBytes32DescComparator();

      await avlTree.insertUintToBytes32(encodeBytes32String("2"), 20);
      await avlTree.insertUintToBytes32(encodeBytes32String("4"), 22);
      await avlTree.insertUintToBytes32(encodeBytes32String("1"), 12);
      await avlTree.insertUintToBytes32(encodeBytes32String("6"), 2);
      await avlTree.insertUintToBytes32(encodeBytes32String("3"), 112);
      await avlTree.insertUintToBytes32(encodeBytes32String("5"), 2);

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String("4"));
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("4"))).to.be.equal(22);

      expect(await avlTree.getMinBytes32()).to.equal(encodeBytes32String("6"));
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("6"))).to.be.equal(2);

      expect(await avlTree.getMaxBytes32()).to.equal(encodeBytes32String("1"));
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("1"))).to.be.equal(12);

      expect(await avlTree.treeSizeBytes32()).to.equal(6);
      expect(await avlTree.inOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([6, 5, 4, 3, 2, 1]));
      expect(await avlTree.preOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([4, 6, 5, 2, 3, 1]));
      expect(await avlTree.postOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([5, 6, 3, 1, 2, 4]));
    });

    it("should remove nodes in the bytes32 tree correctly", async () => {
      await avlTree.insertUintToBytes32(encodeBytes32String("2"), 2);
      await avlTree.insertUintToBytes32(encodeBytes32String("1"), 1);
      await avlTree.insertUintToBytes32(encodeBytes32String("5"), 5);
      await avlTree.insertUintToBytes32(encodeBytes32String("4"), 6);

      await avlTree.removeBytes32(encodeBytes32String("2"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String("4"));

      expect(await avlTree.treeSizeBytes32()).to.equal(3);
      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.false;
      expect(await avlTree.inOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([1, 4, 5]));
      expect(await avlTree.preOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([4, 1, 5]));
      expect(await avlTree.postOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([1, 5, 4]));

      await avlTree.insertUintToBytes32(encodeBytes32String("3"), 3);
      await avlTree.insertUintToBytes32(encodeBytes32String("6"), 4);
      await avlTree.insertUintToBytes32(encodeBytes32String("2"), 2);

      await avlTree.removeBytes32(encodeBytes32String("1"));
      await avlTree.removeBytes32(encodeBytes32String("3"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String("4"));
      expect(await avlTree.treeSizeBytes32()).to.equal(4);

      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.true;
      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.false;
      expect(await avlTree.searchBytes32(encodeBytes32String("3"))).to.be.false;

      expect(await avlTree.inOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([2, 4, 5, 6]));
      expect(await avlTree.preOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([4, 2, 5, 6]));
      expect(await avlTree.postOrderTraversalBytes32()).to.deep.equal(uintToBytes32Array([2, 6, 5, 4]));

      await avlTree.removeBytes32(encodeBytes32String("2"));
      await avlTree.removeBytes32(encodeBytes32String("5"));
      await avlTree.removeBytes32(encodeBytes32String("6"));
      await avlTree.removeBytes32(encodeBytes32String("4"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String(""));
      expect(await avlTree.treeSizeBytes32()).to.equal(0);
    });

    it("should handle searching in the bytes32 tree correctly", async () => {
      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.false;

      await avlTree.insertUintToBytes32(encodeBytes32String("1"), 18);

      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.true;
      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.false;
      expect(await avlTree.searchBytes32(encodeBytes32String("0"))).to.be.false;
    });

    it("should check if custom comparator is set for the bytes32 tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.false;

      await avlTree.setBytes32DescComparator();

      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.true;
    });
  });

  describe("Address Tree", () => {
    it("should insert nodes to the address tree correctly", async () => {
      await avlTree.setUintValueComparatorAddress();

      await avlTree.insertUintToAddress(USER1, 10);
      await avlTree.insertUintToAddress(USER2, 22);
      await avlTree.insertUintToAddress(USER3, 15);
      await avlTree.insertUintToAddress(USER4, 6);
      await avlTree.insertUintToAddress(USER5, 16);
      await avlTree.insertUintToAddress(USER6, 17);

      expect(await avlTree.rootAddress()).to.equal(USER3);
      expect(await avlTree.getUintValueAddress(USER3)).to.be.equal(15);

      expect(await avlTree.getMinAddress()).to.equal(USER4);
      expect(await avlTree.getUintValueAddress(USER4)).to.be.equal(6);

      expect(await avlTree.getMaxAddress()).to.equal(USER2);
      expect(await avlTree.getUintValueAddress(USER2)).to.be.equal(22);

      expect(await avlTree.treeSizeAddress()).to.equal(6);
      expect(await avlTree.inOrderTraversalAddress()).to.deep.equal([
        USER4.address,
        USER1.address,
        USER3.address,
        USER5.address,
        USER6.address,
        USER2.address,
      ]);
      expect(await avlTree.preOrderTraversalAddress()).to.deep.equal([
        USER3.address,
        USER1.address,
        USER4.address,
        USER6.address,
        USER5.address,
        USER2.address,
      ]);
      expect(await avlTree.postOrderTraversalAddress()).to.deep.equal([
        USER4.address,
        USER1.address,
        USER5.address,
        USER2.address,
        USER6.address,
        USER3.address,
      ]);
    });

    it("should remove nodes in the address tree correctly", async () => {
      await avlTree.setUintValueComparatorAddress();

      await avlTree.insertUintToAddress(USER1, 2);
      await avlTree.insertUintToAddress(USER2, 1);
      await avlTree.insertUintToAddress(USER3, 5);
      await avlTree.insertUintToAddress(USER4, 6);

      await avlTree.removeAddress(USER1);

      expect(await avlTree.rootAddress()).to.equal(USER3);
      expect(await avlTree.treeSizeAddress()).to.equal(3);
      expect(await avlTree.searchAddress(USER1)).to.be.false;
      expect(await avlTree.inOrderTraversalAddress()).to.deep.equal([USER2.address, USER3.address, USER4.address]);
      expect(await avlTree.preOrderTraversalAddress()).to.deep.equal([USER3.address, USER2.address, USER4.address]);
      expect(await avlTree.postOrderTraversalAddress()).to.deep.equal([USER2.address, USER4.address, USER3.address]);

      await avlTree.insertUintToAddress(USER5, 3);
      await avlTree.insertUintToAddress(USER6, 4);
      await avlTree.insertUintToAddress(USER1, 2);

      await avlTree.removeAddress(USER2);
      await avlTree.removeAddress(USER5);

      expect(await avlTree.rootAddress()).to.equal(USER6);
      expect(await avlTree.treeSizeAddress()).to.equal(4);

      expect(await avlTree.searchAddress(USER1)).to.be.true;
      expect(await avlTree.searchAddress(USER2)).to.be.false;
      expect(await avlTree.searchAddress(USER5)).to.be.false;

      expect(await avlTree.inOrderTraversalAddress()).to.deep.equal([
        USER1.address,
        USER6.address,
        USER3.address,
        USER4.address,
      ]);
      expect(await avlTree.preOrderTraversalAddress()).to.deep.equal([
        USER6.address,
        USER1.address,
        USER3.address,
        USER4.address,
      ]);
      expect(await avlTree.postOrderTraversalAddress()).to.deep.equal([
        USER1.address,
        USER4.address,
        USER3.address,
        USER6.address,
      ]);

      await avlTree.removeAddress(USER1);
      await avlTree.removeAddress(USER3);
      await avlTree.removeAddress(USER4);
      await avlTree.removeAddress(USER6);

      expect(await avlTree.rootAddress()).to.equal(ZERO_ADDR);
      expect(await avlTree.treeSizeAddress()).to.equal(0);
    });

    it("should handle searching in the address tree correctly", async () => {
      expect(await avlTree.searchAddress(USER1)).to.be.false;

      await avlTree.insertUintToAddress(USER1, 2);

      expect(await avlTree.searchAddress(USER1)).to.be.true;
      expect(await avlTree.searchAddress(USER5)).to.be.false;
      expect(await avlTree.searchAddress(ZERO_ADDR)).to.be.false;
    });

    it("should check if custom comparator is set for the address tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetAddress()).to.be.false;

      await avlTree.setAddressDescComparator();

      expect(await avlTree.isCustomComparatorSetAddress()).to.be.true;
    });
  });
});
