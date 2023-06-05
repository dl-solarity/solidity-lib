const { assert } = require("chai");

const { accounts } = require("../../../scripts/utils/utils");
const { getRoot, buildSparseMerkleTree } = require("../../helpers/merkle-tree-helper");

const IncrementalMerkleTreeMock = artifacts.require("IncrementalMerkleTreeMock");

describe("IncrementalMerkleTree", () => {
  let OWNER;
  let USER1;

  let merkleTree;

  let localMerkleTree;

  beforeEach(async () => {
    OWNER = await accounts(0);
    USER1 = await accounts(1);

    merkleTree = await IncrementalMerkleTreeMock.new();

    localMerkleTree = buildSparseMerkleTree([], 0);
  });

  function getBytes32ElementHash(element) {
    return web3.utils.keccak256(web3.utils.encodePacked({ type: "bytes32", value: element }));
  }

  function getUintElementHash(element) {
    return web3.utils.keccak256(web3.utils.encodePacked({ type: "uint256", value: element }));
  }

  function getAddressElementHash(element) {
    return web3.utils.keccak256(web3.eth.abi.encodeParameter("address", element));
  }

  describe("Uint IMT", () => {
    it("should add element to tree", async () => {
      const element = 1234;

      await merkleTree.addUint(element);

      const elementHash = getUintElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      assert.equal(await merkleTree.getUintRoot(), getRoot(localMerkleTree));

      assert.equal(await merkleTree.getUintTreeLength(), 1);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 33; i++) {
        const element = i;

        await merkleTree.addUint(element);

        const elementHash = getUintElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, await merkleTree.getUintTreeHeight());

        assert.equal(await merkleTree.getUintRoot(), getRoot(localMerkleTree));

        assert.equal(await merkleTree.getUintTreeLength(), i);
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      assert.equal(await merkleTree.getUintRoot(), getRoot(localMerkleTree));
    });
  });

  describe("Bytes32 IMT", () => {
    it("should add element to tree", async () => {
      const element = "0x1234";

      await merkleTree.addBytes32(element);

      const elementHash = getBytes32ElementHash("0x1234");

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      assert.equal(await merkleTree.getBytes32Root(), getRoot(localMerkleTree));

      assert.equal(await merkleTree.getBytes32TreeLength(), 1);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 33; i++) {
        const element = `0x${i}234`;

        await merkleTree.addBytes32(element);

        const elementHash = getBytes32ElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, await merkleTree.getBytes32TreeHeight());

        assert.equal(await merkleTree.getBytes32Root(), getRoot(localMerkleTree));

        assert.equal(await merkleTree.getBytes32TreeLength(), i);
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      assert.equal(await merkleTree.getBytes32Root(), getRoot(localMerkleTree));
    });
  });

  describe("Address IMT", () => {
    it("should add element to tree", async () => {
      const element = USER1;

      await merkleTree.addAddress(element);

      const elementHash = getAddressElementHash(element);

      localMerkleTree = buildSparseMerkleTree([elementHash], 1);

      assert.equal(await merkleTree.getAddressRoot(), getRoot(localMerkleTree));

      assert.equal(await merkleTree.getAddressTreeLength(), 1);
    });

    it("should add elements to tree", async () => {
      const elements = [];

      for (let i = 1; i < 10; i++) {
        const element = await accounts(i);

        await merkleTree.addAddress(element);

        const elementHash = getAddressElementHash(element);

        elements.push(elementHash);

        localMerkleTree = buildSparseMerkleTree(elements, await merkleTree.getAddressTreeHeight());

        assert.equal(await merkleTree.getAddressRoot(), getRoot(localMerkleTree));

        assert.equal(await merkleTree.getAddressTreeLength(), i);
      }
    });

    it("should return zeroHash if tree is empty", async () => {
      assert.equal(await merkleTree.getAddressRoot(), getRoot(localMerkleTree));
    });
  });
});
