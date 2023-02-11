const { MerkleTree } = require("merkletreejs");

const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");
const { web3 } = require("hardhat");
const { ZERO_BYTES32 } = require("../../scripts/utils/constants");

const MerkleWhitelisted = artifacts.require("MerkleWhitelistedMock");

describe("MerkleWhitelisted", () => {
  let OWNER;

  let merkle;
  let leaves;
  let tree;
  let users;

  function getRoot() {
    return "0x" + tree.getRoot().toString("hex");
  }

  function getProof(leaf) {
    return tree.getProof(web3.utils.keccak256(leaf)).map((e) => "0x" + e.data.toString("hex"));
  }

  async function buildTree() {
    tree = new MerkleTree(leaves, web3.utils.keccak256, { hashLeaves: true, sortPairs: true });

    await merkle.setMerkleRoot(getRoot());
  }

  async function addToWhitelist(leaf) {
    leaves.push(leaf);

    await buildTree();
  }

  function buildAmountLeaf(user, amount) {
    return web3.utils.encodePacked({ value: amount, type: "uint256" }, { value: user, type: "address" });
  }

  before(async () => {
    OWNER = await accounts(0);

    users = await Promise.all([1, 2, 3, 4, 5].map(async (i) => await accounts(i)));
  });

  beforeEach(async () => {
    merkle = await MerkleWhitelisted.new();
  });

  describe("#getMerkleRoot #_setMerkleRoot", () => {
    beforeEach(async () => {
      leaves = [];

      await buildTree();
    });

    it("should be zero if root is not set yet", async () => {
      assert.equal(await merkle.getMerkleRoot(), ZERO_BYTES32);
    });

    it("should change merkle tree root properly", async () => {
      await addToWhitelist(users[0]);
      const root1 = getRoot();

      assert.equal(await merkle.getMerkleRoot(), root1);

      await addToWhitelist(users[1]);
      const root2 = getRoot();

      assert.equal(await merkle.getMerkleRoot(), root2);
      assert.notEqual(root1, root2);
    });
  });

  describe("#onlyWhitelisted", () => {
    const amounts = [100, 500, 200, 1, 3000];

    beforeEach(async () => {
      leaves = users.map((e, index) => buildAmountLeaf(e, amounts[index]));

      await buildTree();
    });

    it("should revert if the user is incorrect", async () => {
      await truffleAssert.reverts(
        merkle.onlyWhitelistedMethod(amounts[0], getProof(leaves[0]), { from: users[1] }),
        "MerkleWhitelisted: not whitelisted"
      );
    });

    it("should revert if the amount is incorrect", async () => {
      await truffleAssert.reverts(
        merkle.onlyWhitelistedMethod(amounts[1], getProof(leaves[0]), { from: users[0] }),
        "MerkleWhitelisted: not whitelisted"
      );
    });

    it("should revert if the proof is incorrect", async () => {
      await truffleAssert.reverts(
        merkle.onlyWhitelistedMethod(amounts[0], getProof(leaves[1]), { from: users[0] }),
        "MerkleWhitelisted: not whitelisted"
      );
    });

    it("should not revert if all conditions are met", async () => {
      for (let i = 0; i < 5; i++) {
        truffleAssert.eventEmitted(
          (await merkle.onlyWhitelistedMethod(amounts[i], getProof(leaves[i]), { from: users[i] })).receipt,
          "WhitelistedData"
        );
      }
    });
  });

  describe("#onlyWhitelistedUser", () => {
    beforeEach(async () => {
      leaves = users;

      await buildTree();
    });

    it("should revert if the user is incorrect", async () => {
      await truffleAssert.reverts(
        merkle.onlyWhitelistedUserMethod(getProof(leaves[0]), { from: OWNER }),
        "MerkleWhitelisted: not whitelisted"
      );
    });

    it("should revert if the proof is incorrect", async () => {
      await truffleAssert.reverts(
        merkle.onlyWhitelistedUserMethod(getProof(leaves[1]), { from: users[0] }),
        "MerkleWhitelisted: not whitelisted"
      );
    });

    it("should not revert if all conditions are met", async () => {
      for (let i = 0; i < 5; i++) {
        truffleAssert.eventEmitted(
          (await merkle.onlyWhitelistedUserMethod(getProof(leaves[i]), { from: users[i] })).receipt,
          "WhitelistedUser"
        );
      }
    });
  });
});
