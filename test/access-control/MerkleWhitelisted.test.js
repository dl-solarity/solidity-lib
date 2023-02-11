const { MerkleTree } = require("merkletreejs");

const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const MerkleWhitelisted = artifacts.require("MerkleWhitelisted");

describe("MerkleWhitelisted", () => {
  let OWNER;

  let merkle;

  before("setup", async () => {
    OWNER = await accounts(0);
  });

  beforeEach("setup", async () => {
    merkle = await MerkleWhitelisted.new();
  });
});
