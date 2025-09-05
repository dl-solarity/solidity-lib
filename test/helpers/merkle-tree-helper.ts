import { ZeroHash, keccak256 } from "ethers";

import { addHexPrefix } from "./bytes-helpers.ts";
import { MerkleTree } from "merkletreejs";

export function getRoot(tree: MerkleTree): string {
  const root = tree.getRoot();

  if (root.length == 0) {
    return ZeroHash;
  }

  return addHexPrefix(root.toString("hex"));
}

export function getProof(tree: MerkleTree, leaf: any, hashFn: any = keccak256): string[] {
  return tree.getProof(hashFn(leaf)).map((e) => addHexPrefix(e.data.toString("hex")));
}

export function buildTree(leaves: any, hashFn: any = keccak256): MerkleTree {
  return new MerkleTree(leaves, hashFn, { hashLeaves: true, sortPairs: true });
}

export function buildSparseMerkleTree(leaves: any, height: number, hashFn: any = keccak256): MerkleTree {
  const elementsToAdd = 2 ** height - leaves.length;
  const zeroHash = hashFn(ZeroHash);
  const zeroElements = Array(elementsToAdd).fill(zeroHash);

  return new MerkleTree([...leaves, ...zeroElements], hashFn, {
    hashLeaves: false,
    sortPairs: false,
  });
}

export function addElementToTree(tree: MerkleTree, element: any, hashFn: any = keccak256) {
  return new MerkleTree([...tree.getLeaves(), element], hashFn, {
    hashLeaves: true,
    sortPairs: true,
  });
}
