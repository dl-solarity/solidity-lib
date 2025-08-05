import { ZeroHash } from "ethers";
import { parseCuint, reverseByte, reverseBytes } from "./bytes-helper";

export class MerkleRawProofParser {
  private txidReversed: string;
  private txCountInBlock: number;
  private hashes: string[];
  private flagPath: string;
  private maxDepth: number;
  private nodeCountPerLevel: number[];
  private txIndex: number;
  private sortedHashes: string[];
  private directions: number[];

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
      this.hashes.push("0x" + rawHashes.slice(i * 64, (i + 1) * 64));
    }

    offset = offset + Number(hashCount) * 64;

    const [byteFlagsCount, byteFlagsCountSize] = parseCuint(withoutHeader, offset);

    offset += byteFlagsCountSize;

    const byteFlags = withoutHeader.slice(offset, offset + 2 * Number(byteFlagsCount));

    this.flagPath = this.processFlags(byteFlags);
    this.maxDepth = Math.ceil(Math.log2(this.txCountInBlock));
    this.nodeCountPerLevel = this.getNodeCountPerLevel(this.txCountInBlock, this.maxDepth);

    [this.txIndex, this.sortedHashes] = this.processTree(0, 0, 0, 0, 0, []);

    this.directions = this.processDirections(this.txIndex, this.txCountInBlock);
  }

  getTxidReversed(): string {
    return this.txidReversed;
  }

  getTxIndex(): number {
    return this.txIndex;
  }

  getSortedHashes(): string[] {
    return this.sortedHashes;
  }

  getDirections(): number[] {
    return this.directions;
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

  private processDirections(txIndex: number, totalTransactions: number) {
    let directions: number[] = [];
    let curIndex = txIndex;
    let levelSize = totalTransactions;

    while (levelSize > 1) {
      if (curIndex % 2 == 0) {
        if (levelSize % 2 == 1 && levelSize - 1 == curIndex) directions.push(2);
        else directions.push(0);
      } else directions.push(1);

      curIndex = Math.floor(curIndex / 2);
      levelSize = Math.ceil(levelSize / 2);
    }

    return directions;
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
      //this is the tx we searched for
      ++currentHash;

      if (this.isNodeWithoutPair(depth, nodePosition)) {
        sortedHashes.push(ZeroHash);
      } else if (this.isLastLeaf(nodePosition, currentHash)) {
        sortedHashes.push(this.hashes[currentHash]);
      }

      sortedHashes.reverse();

      return [txIndex, sortedHashes];
    }

    if (depth == this.maxDepth) {
      //this is neighbour of the tx we searched for
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

  private nodesCountIsUneven(level: number): boolean {
    return this.nodeCountPerLevel[level]! % 2 == 1;
  }

  private isNodeWithoutPair(depth: number, nodePosition: number): boolean {
    return depth != 0 && this.nodesCountIsUneven(depth) && nodePosition + 1 == this.nodeCountPerLevel[depth];
  }

  private isLeftNode(depth: number, nodePosition: number): boolean {
    return depth != 0 && nodePosition % 2 == 0;
  }

  private isLastLeaf(nodePosition: number, currentHash: number): boolean {
    return nodePosition % 2 == 0 && currentHash < this.hashes.length;
  }
}
