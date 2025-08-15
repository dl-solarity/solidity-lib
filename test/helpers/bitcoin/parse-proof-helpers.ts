import { sha256, ZeroHash } from "ethers";
import { addHexPrefix, reverseByte, reverseBytes } from "../bytes-helpers";
import { parseCuint } from "./parse-tx-helper";

export class MerkleRawProofParser {
  private txidReversed: string;
  private txCountInBlock: number;
  private hashes: string[];
  private flagPath: string;
  private maxDepth: number;
  private nodeCountPerLevel: number[];
  private txIndex: number;
  private siblings: string[];

  constructor(txid: string, rawProof: string) {
    this.txidReversed = reverseBytes(txid);

    const withoutHeader = rawProof.slice(160);

    const txCountOffset = 8;
    let offset = txCountOffset;

    const txCountRaw = withoutHeader.slice(0, offset);
    this.txCountInBlock = parseInt(reverseBytes(txCountRaw), 16);
    const [hashCount, hashCountSize] = parseCuint(withoutHeader, offset);

    offset += hashCountSize;

    const rawHashes = withoutHeader.slice(offset, offset + Number(hashCount) * 64);

    this.hashes = [];
    for (let i = 0; i < hashCount; i++) {
      this.hashes.push(addHexPrefix(rawHashes.slice(i * 64, (i + 1) * 64)));
    }

    offset = offset + Number(hashCount) * 64;

    const [byteFlagsCount, byteFlagsCountSize] = parseCuint(withoutHeader, offset);

    offset += byteFlagsCountSize;

    const byteFlags = withoutHeader.slice(offset, offset + 2 * Number(byteFlagsCount));

    this.flagPath = this.processFlags(byteFlags);
    this.maxDepth = Math.ceil(Math.log2(this.txCountInBlock));
    this.nodeCountPerLevel = this.getNodeCountPerLevel(this.txCountInBlock, this.maxDepth);

    [this.txIndex, this.siblings] = this.processTree(0, 0, 0, 0, 0, []);
  }

  getTxidReversed(): string {
    return this.txidReversed;
  }

  getTxIndex(): number {
    return this.txIndex;
  }

  getSiblings(): string[] {
    return this.siblings;
  }

  private processFlags(flagBytes: string): string {
    let directions = "";

    for (let i = 0; i < flagBytes.length; i += 2) {
      directions += reverseByte(flagBytes.substring(i, i + 2));
    }

    return directions;
  }

  private getNodeCountPerLevel(txCount: number, depth: number): number[] {
    let result: number[] = [];
    let levelSize = txCount;

    for (let i = depth; i >= 0; i--) {
      result[depth] = levelSize;

      levelSize = Math.ceil(levelSize / 2);
      depth--;
    }

    return result;
  }

  private calculateSiblings(leaf: string, txIndex: number, sortedHashes: string[]): string[] {
    let computedHash = leaf;

    for (let i = 0; i < sortedHashes.length; i++) {
      if (sortedHashes[i] == ZeroHash) {
        sortedHashes[i] = computedHash;
      }

      const pairToHash =
        (txIndex & 1) == 0
          ? computedHash.slice(2) + sortedHashes[i].slice(2)
          : sortedHashes[i].slice(2) + computedHash.slice(2);

      computedHash = sha256(sha256(addHexPrefix(pairToHash)));

      txIndex = txIndex / 2;
    }

    return sortedHashes;
  }

  private processTree(
    depth: number,
    currentFlag: number,
    txIndex: number,
    currentHash: number,
    nodePosition: number,
    sortedHashes: string[],
  ): [number, string[]] {
    if (depth == this.maxDepth && this.flagPath.at(currentFlag) == "1") {
      // this is the tx we searched for
      const leaf = this.hashes[currentHash];

      if (this.isNodeWithoutPair(depth, nodePosition)) {
        sortedHashes.push(this.hashes[currentHash]);
      } else if (this.hasSiblingAtRight(nodePosition, currentHash)) {
        sortedHashes.push(this.hashes[currentHash + 1]);
      }

      sortedHashes.reverse();

      const siblings = this.calculateSiblings(leaf, txIndex, sortedHashes);

      return [txIndex, siblings];
    }

    if (depth == this.maxDepth) {
      // this is neighbour of the tx we searched for
      sortedHashes.push(this.hashes[currentHash]);

      return this.processTree(depth, currentFlag + 1, txIndex + 1, currentHash + 1, nodePosition + 1, sortedHashes);
    }

    if (this.flagPath.at(currentFlag) == "1") {
      if (this.isNodeWithoutPair(depth, nodePosition)) {
        sortedHashes.push(ZeroHash);
      } else if (this.isLeftNode(depth, nodePosition)) {
        const rightNodeHash = this.hashes.pop();

        if (!rightNodeHash) throw Error(`No hashes left at depth ${depth}`);

        sortedHashes.push(rightNodeHash);
      }

      return this.processTree(depth + 1, currentFlag + 1, txIndex, currentHash, nodePosition * 2, sortedHashes);
    }

    const txSkipped = 2 ** (this.maxDepth - depth);

    sortedHashes.push(this.hashes[currentHash]);

    return this.processTree(
      depth,
      currentFlag + 1,
      txIndex + txSkipped,
      currentHash + 1,
      nodePosition + 1,
      sortedHashes,
    );
  }

  private nodesCountIsOdd(level: number): boolean {
    return (this.nodeCountPerLevel[level]! & 1) == 1;
  }

  private isNodeWithoutPair(depth: number, nodePosition: number): boolean {
    return depth != 0 && this.nodesCountIsOdd(depth) && nodePosition + 1 == this.nodeCountPerLevel[depth];
  }

  private isLeftNode(depth: number, nodePosition: number): boolean {
    return depth != 0 && (nodePosition & 1) == 0;
  }

  private hasSiblingAtRight(nodePosition: number, currentHash: number): boolean {
    return (nodePosition & 1) == 0 && currentHash + 1 < this.hashes.length;
  }
}
