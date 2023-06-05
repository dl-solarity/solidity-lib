const { MerkleTree } = require("merkletreejs");

function getRoot(tree) {
  return "0x" + tree.getRoot().toString("hex");
}

function getProof(tree, leaf) {
  return tree.getProof(web3.utils.keccak256(leaf)).map((e) => "0x" + e.data.toString("hex"));
}

function buildTree(leaves) {
  return new MerkleTree(leaves, web3.utils.keccak256, { hashLeaves: true, sortPairs: true });
}

function buildSparseMerkleTree(leaves, height) {
  const elementsToAdd = 2 ** height - leaves.length;
  const zeroHash = web3.utils.keccak256("0x0000000000000000000000000000000000000000000000000000000000000000");
  const zeroElements = Array(elementsToAdd).fill(zeroHash);

  return new MerkleTree([...leaves, ...zeroElements], web3.utils.keccak256, {
    hashLeaves: false,
    sortPairs: false,
  });
}

function addElementToTree(tree, element) {
  return new MerkleTree([...tree.getLeaves(), element], web3.utils.keccak256, {
    hashLeaves: true,
    sortPairs: true,
  });
}

module.exports = {
  getRoot,
  getProof,
  buildTree,
  buildSparseMerkleTree,
  addElementToTree,
};
