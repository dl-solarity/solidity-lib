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
        await avlTree.insertUintToUint(4, 1);
        await avlTree.insertUintToUint(12, 2);
        await avlTree.insertUintToUint(1, 3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(3);

        let traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 12]);
        expect(traversal[1]).to.deep.equal([3, 1, 2]);

        await avlTree.insertUintToUint(200, 4);
        await avlTree.insertUintToUint(10, 5);
        await avlTree.insertUintToUint(5, 6);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.treeSizeUint()).to.equal(6);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 5, 10, 12, 200]);
        expect(traversal[1]).to.deep.equal([3, 1, 6, 5, 2, 4]);

        await avlTree.insertUintToUint(15, 7);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.treeSizeUint()).to.equal(7);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 5, 10, 12, 15, 200]);
        expect(traversal[1]).to.deep.equal([3, 1, 6, 5, 2, 7, 4]);

        await avlTree.insertUintToUint(2, 8);
        await avlTree.insertUintToUint(3, 9);

        expect(await avlTree.rootUint()).to.equal(10);
        expect(await avlTree.treeSizeUint()).to.equal(9);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 3, 4, 5, 10, 12, 15, 200]);
        expect(traversal[1]).to.deep.equal([3, 8, 9, 1, 6, 5, 2, 7, 4]);
      });

      it("should insert address values to the uint tree correctly", async () => {
        await avlTree.insertAddressToUint(2, USER2);
        await avlTree.insertAddressToUint(6, USER1);
        await avlTree.insertAddressToUint(4, USER2);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(3);

        let traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([2, 4, 6]);
        expect(traversal[1]).to.deep.equal([USER2.address, USER2.address, USER1.address]);

        await avlTree.insertAddressToUint(1, USER2);
        await avlTree.insertAddressToUint(13, USER4);
        await avlTree.insertAddressToUint(7, USER1);
        await avlTree.insertAddressToUint(5, USER3);

        expect(await avlTree.rootUint()).to.equal(4);
        expect(await avlTree.treeSizeUint()).to.equal(7);

        traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 4, 5, 6, 7, 13]);
        expect(traversal[1]).to.deep.equal([
          USER2.address,
          USER2.address,
          USER2.address,
          USER3.address,
          USER1.address,
          USER1.address,
          USER4.address,
        ]);
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

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 4, 5, 16, 17, 18, 19, 20, 111]);
        expect(traversal[1]).to.deep.equal([20, 10, 7, 10, 20, 100, 20, 250, 4, 10]);
      });

      it("should not allow to insert 0 as key to the uint tree", async () => {
        await expect(avlTree.insertUintToUint(0, 100)).to.be.revertedWith("AvlTree: key is not allowed to be 0");
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

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 2, 4, 6, 7, 10]);
        expect(traversal[1]).to.deep.equal([2, 4, 10, 10, 10, 10]);
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

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([1, 4, 6, 7, 9]);
        expect(traversal[1]).to.deep.equal([2, 20, 11, 1, 1]);
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

        const traversal = await avlTree.traverseUint();
        expect(traversal[0].length).to.be.equal(0);
        expect(traversal[1].length).to.be.equal(0);
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

        const traversal = await avlTree.traverseUint();
        expect(traversal[0]).to.deep.equal([6, 5, 4, 3, 2, 1]);
        expect(traversal[1]).to.deep.equal([4, 1, 10, 200, 3, 4]);
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

        expect(await avlTree.searchUint(2)).to.be.equal(1);
      });

      it("should handle searching for the non-existing key in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 1);

        expect(await avlTree.searchUint(3)).to.be.equal(0);
      });

      it("should handle searching for the zero key in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 1);

        expect(await avlTree.searchUint(0)).to.be.equal(0);
      });

      it("should get value for the existing node in the uint tree correctly", async () => {
        await avlTree.insertUintToUint(1, 4);
        await avlTree.insertUintToUint(2, 2);

        await avlTree.insertAddressToUint(3, USER1);
        await avlTree.insertAddressToUint(4, USER2);

        expect(await avlTree.getUintValueUint(1)).to.deep.equal([true, 4]);
        expect(await avlTree.getUintValueUint(2)).to.deep.equal([true, 2]);
        expect(await avlTree.getUintValueUint(5)).to.deep.equal([false, 0]);

        expect(await avlTree.getAddressValueUint(3)).to.deep.equal([true, USER1.address]);
        expect(await avlTree.getAddressValueUint(4)).to.deep.equal([true, USER2.address]);
        expect(await avlTree.getAddressValueUint(6)).to.deep.equal([false, ZERO_ADDR]);
      });

      it("should handle getting value for the non-existing node in the uint tree correctly", async () => {
        expect(await avlTree.getUintValueUint(1)).to.deep.equal([false, 0]);

        await avlTree.insertUintToUint(1, 30);
        expect(await avlTree.getUintValueUint(2)).to.deep.equal([false, 0]);
        expect(await avlTree.getUintValueUint(0)).to.deep.equal([false, 0]);
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

        await avlTree.setUintDescComparator();

        expect(await avlTree.isCustomComparatorSetUint()).to.be.true;
      });

      it("should traverse the uint tree correctly", async () => {
        await avlTree.insertUintToUint(2, 10);
        await avlTree.insertUintToUint(4, 11);
        await avlTree.insertUintToUint(1, 12);
        await avlTree.insertUintToUint(6, 13);
        await avlTree.insertUintToUint(7, 14);

        let fullTraversal = await avlTree.traverseUint();
        expect(fullTraversal[0]).to.deep.equal([1, 2, 4, 6, 7]);
        expect(fullTraversal[1]).to.deep.equal([12, 10, 11, 13, 14]);

        let firstThreeTraversal = await avlTree.traverseFirstThreeUint();
        expect(firstThreeTraversal[0]).to.deep.equal([1, 2, 4]);
        expect(firstThreeTraversal[1]).to.deep.equal([12, 10, 11]);

        await expect(avlTree.brokenTraversalUint()).to.be.revertedWith("Traversal: No more nodes");
      });
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
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("4"))).to.deep.equal([true, 22]);

      expect(await avlTree.treeSizeBytes32()).to.equal(6);

      let fullTraversal = await avlTree.traverseBytes32();
      expect(fullTraversal[0]).to.deep.equal(uintToBytes32Array([6, 5, 4, 3, 2, 1]));
      expect(fullTraversal[1]).to.deep.equal([2, 2, 22, 112, 20, 12]);

      let firstThreeTraversal = await avlTree.traverseFirstThreeBytes32();
      expect(firstThreeTraversal[0]).to.deep.equal(uintToBytes32Array([6, 5, 4]));
      expect(firstThreeTraversal[1]).to.deep.equal([2, 2, 22]);
    });

    it("should remove nodes in the bytes32 tree correctly", async () => {
      await avlTree.insertUintToBytes32(encodeBytes32String("2"), 2);
      await avlTree.insertUintToBytes32(encodeBytes32String("1"), 1);
      await avlTree.insertUintToBytes32(encodeBytes32String("5"), 5);
      await avlTree.insertUintToBytes32(encodeBytes32String("4"), 6);

      await avlTree.removeBytes32(encodeBytes32String("2"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String("4"));

      expect(await avlTree.treeSizeBytes32()).to.equal(3);
      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.equal(0);
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("2"))).to.deep.equal([false, 0]);

      let traversal = await avlTree.traverseBytes32();
      expect(traversal[0]).to.deep.equal(uintToBytes32Array([1, 4, 5]));
      expect(traversal[1]).to.deep.equal([1, 6, 5]);

      await avlTree.insertUintToBytes32(encodeBytes32String("3"), 3);
      await avlTree.insertUintToBytes32(encodeBytes32String("6"), 4);
      await avlTree.insertUintToBytes32(encodeBytes32String("2"), 2);

      await avlTree.removeBytes32(encodeBytes32String("1"));
      await avlTree.removeBytes32(encodeBytes32String("3"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String("4"));
      expect(await avlTree.treeSizeBytes32()).to.equal(4);

      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.equal(7);
      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.equal(0);
      expect(await avlTree.searchBytes32(encodeBytes32String("3"))).to.be.equal(0);

      expect(await avlTree.getUintValueBytes32(encodeBytes32String("2"))).to.deep.equal([true, 2]);
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("1"))).to.deep.equal([false, 0]);
      expect(await avlTree.getUintValueBytes32(encodeBytes32String("3"))).to.deep.equal([false, 0]);

      traversal = await avlTree.traverseBytes32();
      expect(traversal[0]).to.deep.equal(uintToBytes32Array([2, 4, 5, 6]));
      expect(traversal[1]).to.deep.equal([2, 6, 5, 4]);

      await avlTree.removeBytes32(encodeBytes32String("2"));
      await avlTree.removeBytes32(encodeBytes32String("5"));
      await avlTree.removeBytes32(encodeBytes32String("6"));
      await avlTree.removeBytes32(encodeBytes32String("4"));

      expect(await avlTree.rootBytes32()).to.equal(encodeBytes32String(""));
      expect(await avlTree.treeSizeBytes32()).to.equal(0);
    });

    it("should handle searching in the bytes32 tree correctly", async () => {
      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.equal(0);

      await avlTree.insertUintToBytes32(encodeBytes32String("1"), 18);

      expect(await avlTree.searchBytes32(encodeBytes32String("1"))).to.be.equal(1);
      expect(await avlTree.searchBytes32(encodeBytes32String("2"))).to.be.equal(0);
      expect(await avlTree.searchBytes32(encodeBytes32String("0"))).to.be.equal(0);
    });

    it("should check if custom comparator is set for the bytes32 tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.false;

      await avlTree.setBytes32DescComparator();

      expect(await avlTree.isCustomComparatorSetBytes32()).to.be.true;
    });
  });

  describe("Address Tree", () => {
    it("should insert nodes to the address tree correctly", async () => {
      let users = [USER1.address, USER2.address, USER3.address, USER4.address, USER5.address, USER6.address];
      let addresses = users.map((user) => user);

      addresses.sort((a, b) => a.localeCompare(b));

      await avlTree.insertUintToAddress(addresses[5], 10);
      await avlTree.insertUintToAddress(addresses[3], 22);
      await avlTree.insertUintToAddress(addresses[4], 15);
      await avlTree.insertUintToAddress(addresses[2], 6);
      await avlTree.insertUintToAddress(addresses[1], 16);

      expect(await avlTree.rootAddress()).to.equal(addresses[4]);
      expect(await avlTree.getUintValueAddress(addresses[4])).to.deep.equal([true, 15]);

      expect(await avlTree.treeSizeAddress()).to.equal(5);

      let traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([addresses[1], addresses[2], addresses[3], addresses[4], addresses[5]]);
      expect(traversal[1]).to.deep.equal([16, 6, 22, 15, 10]);

      await avlTree.insertUintToAddress(addresses[0], 17);

      expect(await avlTree.rootAddress()).to.equal(addresses[2]);
      expect(await avlTree.getUintValueAddress(addresses[2])).to.deep.equal([true, 6]);

      expect(await avlTree.treeSizeAddress()).to.equal(6);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([
        addresses[0],
        addresses[1],
        addresses[2],
        addresses[3],
        addresses[4],
        addresses[5],
      ]);
      expect(traversal[1]).to.deep.equal([17, 16, 6, 22, 15, 10]);

      const firstThreeTraversal = await avlTree.traverseFirstThreeAddress();
      expect(firstThreeTraversal[0]).to.deep.equal([addresses[0], addresses[1], addresses[2]]);
      expect(firstThreeTraversal[1]).to.deep.equal([17, 16, 6]);
    });

    it("should remove nodes in the address tree correctly", async () => {
      let users = [USER1.address, USER2.address, USER3.address, USER4.address, USER5.address, USER6.address];
      let addresses = users.map((user) => user);

      addresses.sort((a, b) => b.localeCompare(a));

      await avlTree.setAddressDescComparator();

      await avlTree.insertUintToAddress(addresses[1], 2);
      await avlTree.insertUintToAddress(addresses[0], 1);
      await avlTree.insertUintToAddress(addresses[4], 5);
      await avlTree.insertUintToAddress(addresses[5], 6);

      await avlTree.removeAddress(addresses[1]);

      expect(await avlTree.rootAddress()).to.equal(addresses[4]);
      expect(await avlTree.treeSizeAddress()).to.equal(3);
      expect(await avlTree.searchAddress(addresses[1])).to.be.equal(0);

      let traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([addresses[0], addresses[4], addresses[5]]);
      expect(traversal[1]).to.deep.equal([1, 5, 6]);

      await avlTree.insertUintToAddress(addresses[2], 3);
      await avlTree.insertUintToAddress(addresses[3], 4);
      await avlTree.insertUintToAddress(addresses[1], 2);

      await avlTree.removeAddress(addresses[2]);
      await avlTree.removeAddress(addresses[4]);

      expect(await avlTree.rootAddress()).to.equal(addresses[3]);
      expect(await avlTree.treeSizeAddress()).to.equal(4);

      expect(await avlTree.searchAddress(addresses[0])).to.be.equal(2);
      expect(await avlTree.searchAddress(addresses[2])).to.be.equal(0);
      expect(await avlTree.searchAddress(addresses[4])).to.be.equal(0);

      expect(await avlTree.getUintValueAddress(addresses[0])).to.deep.equal([true, 1]);
      expect(await avlTree.getUintValueAddress(addresses[2])).to.deep.equal([false, 0]);
      expect(await avlTree.getUintValueAddress(addresses[4])).to.deep.equal([false, 0]);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0]).to.deep.equal([addresses[0], addresses[1], addresses[3], addresses[5]]);
      expect(traversal[1]).to.deep.equal([1, 2, 4, 6]);

      await avlTree.removeAddress(addresses[1]);
      await avlTree.removeAddress(addresses[5]);
      await avlTree.removeAddress(addresses[3]);
      await avlTree.removeAddress(addresses[0]);

      expect(await avlTree.rootAddress()).to.equal(ZERO_ADDR);
      expect(await avlTree.treeSizeAddress()).to.equal(0);

      traversal = await avlTree.traverseAddress();
      expect(traversal[0].length).to.be.equal(0);
      expect(traversal[1].length).to.be.equal(0);
    });

    it("should handle searching in the address tree correctly", async () => {
      expect(await avlTree.searchAddress(USER1)).to.be.equal(0);

      await avlTree.insertUintToAddress(USER1, 2);

      expect(await avlTree.searchAddress(USER1)).to.be.equal(1);
      expect(await avlTree.searchAddress(USER5)).to.be.equal(0);
      expect(await avlTree.searchAddress(ZERO_ADDR)).to.be.equal(0);
    });

    it("should check if custom comparator is set for the address tree correctly", async () => {
      expect(await avlTree.isCustomComparatorSetAddress()).to.be.false;

      await avlTree.setAddressDescComparator();

      expect(await avlTree.isCustomComparatorSetAddress()).to.be.true;
    });
  });
});
