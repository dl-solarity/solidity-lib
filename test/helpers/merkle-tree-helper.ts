import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs";
import { ZERO_BYTES32 } from "@/scripts/utils/constants";

export function getRoot(tree: MerkleTree): string {
  const root = tree.getRoot();

  if (root.length == 0) {
    return ZERO_BYTES32;
  }

  return "0x" + root.toString("hex");
}

export function getProof(tree: MerkleTree, leaf: any): string[] {
  return tree.getProof(ethers.keccak256(leaf)).map((e) => "0x" + e.data.toString("hex"));
}

export function buildTree(leaves: any): MerkleTree {
  return new MerkleTree(leaves, ethers.keccak256, { hashLeaves: true, sortPairs: true });
}

export function buildSparseMerkleTree(leaves: any, height: number): MerkleTree {
  const elementsToAdd = 2 ** height - leaves.length;
  const zeroHash = ethers.keccak256(ZERO_BYTES32);
  const zeroElements = Array(elementsToAdd).fill(zeroHash);

  return new MerkleTree([...leaves, ...zeroElements], ethers.keccak256, {
    hashLeaves: false,
    sortPairs: false,
  });
}

export function addElementToTree(tree: MerkleTree, element: any) {
  return new MerkleTree([...tree.getLeaves(), element], ethers.keccak256, {
    hashLeaves: true,
    sortPairs: true,
  });
}
