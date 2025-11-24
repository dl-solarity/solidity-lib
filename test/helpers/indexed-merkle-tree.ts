import { ethers } from "ethers";

import { poseidonHash } from "./poseidon-hash.ts";

export interface MerkleTreeLevel {
  [index: string]: string;
}

export interface MerkleTreeLevels {
  [level: string]: MerkleTreeLevel;
}

export interface LeavesData {
  [index: string]: LeafData;
}

export interface IndexedLeafData {
  index: bigint;
  value: string;
  nextIndex: bigint;
  isActive: boolean;
}

export interface LeafData {
  value: string;
  nextLeafIndex: bigint;
}

export interface Proof {
  root: string;
  siblings: string[];
  existence: boolean;
  index: bigint;
  value: string;
  nextLeafIndex: bigint;
}

export const LEAVES_LEVEL = 0n;
export const ZERO_IDX = 0n;

export function hashNodePoseidon(leftChild: string, rightChild: string): string {
  const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes32", "uint256"], [leftChild, rightChild]);

  return poseidonHash(encodedData);
}

export function hashIndexedLeafPoseidon(leafData: IndexedLeafData): string {
  const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bool", "uint256", "bytes32", "uint256"],
    [leafData.isActive, leafData.index, leafData.value, leafData.nextIndex],
  );

  return poseidonHash(encodedData);
}

export function hashNode(leftChild: string, rightChild: string): string {
  const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes32", "uint256"], [leftChild, rightChild]);

  return ethers.keccak256(encodedData);
}

export function hashIndexedLeaf(leafData: IndexedLeafData): string {
  const encodedData = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bool", "uint256", "bytes32", "uint256"],
    [leafData.isActive, leafData.index, leafData.value, leafData.nextIndex],
  );

  return ethers.keccak256(encodedData);
}

export function encodeBytes32Value(value: bigint): string {
  return ethers.toBeHex(value, 32);
}

export class IndexedMerkleTree {
  public zeroHashesCache: string[] = [];

  private levels: MerkleTreeLevels = {};
  private leavesData: LeavesData = {};
  private levelsCount: number;
  private maxLevelsCount: number;

  private hashNodeFn: (leftChild: string, rightChild: string) => string;
  private hashLeafFn: (leafData: IndexedLeafData) => string;

  public static buildMerkleTree(
    leavesData?: IndexedLeafData[],
    hashNodeFn: (leftChild: string, rightChild: string) => string = hashNode,
    hashLeafFn: (leafData: IndexedLeafData) => string = hashIndexedLeaf,
    maxLevelsCount: number = 256,
  ): IndexedMerkleTree {
    return new IndexedMerkleTree(
      leavesData ?? [
        {
          index: 0n,
          value: encodeBytes32Value(0n),
          nextIndex: 0n,
          isActive: true,
        },
      ],
      maxLevelsCount,
      hashNodeFn,
      hashLeafFn,
    );
  }

  private constructor(
    leavesData: IndexedLeafData[],
    maxLevelsCount: number,
    hashNodeFn: (leftChild: string, rightChild: string) => string,
    hashLeafFn: (leafData: IndexedLeafData) => string,
  ) {
    this.hashNodeFn = hashNodeFn;
    this.hashLeafFn = hashLeafFn;

    if (leavesData.length === 0) {
      throw new Error("Tree must have leaves.");
    }

    this._precalculateZeroHashes(maxLevelsCount);

    this.levelsCount = Math.ceil(Math.log2(leavesData.length)) + 1;
    this.maxLevelsCount = maxLevelsCount;

    for (let i = 0n; i < BigInt(maxLevelsCount); i++) {
      this.levels[i.toString()] = {};
    }

    if (this.levelsCount > this.maxLevelsCount) {
      throw new Error(`Invalid maxLevelsCount ${maxLevelsCount} parameter.`);
    }

    this._buildTree(leavesData);
  }

  public add(value: string, lowLeafIndex: bigint = this.getLowLeafIndex(value)): bigint {
    const currentLeavesCount = this.getLevelNodesCount(LEAVES_LEVEL);

    if (currentLeavesCount >= 1n << BigInt(this.maxLevelsCount)) {
      throw new Error("Maximum tree capacity reached.");
    }

    if (!this._isLowLeaf(lowLeafIndex, value)) {
      throw new Error(`Index ${lowLeafIndex} not a low leaf index for the value ${value}`);
    }

    const newLeafIndex = currentLeavesCount;
    const nextLeafIndex = this.getLeafData(lowLeafIndex).nextLeafIndex;

    this._updateNextLeafIndex(lowLeafIndex, newLeafIndex);
    this._pushLeaf(newLeafIndex, { value: value, nextLeafIndex: nextLeafIndex });

    return newLeafIndex;
  }

  public update(
    indexToUpdate: bigint,
    currentLowLeafIndex: bigint,
    newValue: string,
    newLowLeafIndex: bigint = this.getLowLeafIndex(newValue),
  ) {
    if (indexToUpdate == ZERO_IDX) {
      throw new Error("Unable to update zero index.");
    }

    if (this.getLeafData(currentLowLeafIndex).nextLeafIndex != indexToUpdate) {
      throw new Error(`Index ${currentLowLeafIndex} not a low leaf for the element with index ${indexToUpdate}`);
    }

    this.leavesData[indexToUpdate.toString()].value = newValue;

    if (newLowLeafIndex != currentLowLeafIndex && newLowLeafIndex != indexToUpdate) {
      if (!this._isLowLeaf(newLowLeafIndex, newValue)) {
        throw new Error(`Index ${newLowLeafIndex} not a low leaf index for the value ${newValue}`);
      }

      const nextLeafIndex = this.getLeafData(newLowLeafIndex).nextLeafIndex;

      this._updateNextLeafIndex(currentLowLeafIndex, this.getLeafData(indexToUpdate).nextLeafIndex);
      this._updateNextLeafIndex(newLowLeafIndex, indexToUpdate);
      this._updateNextLeafIndex(indexToUpdate, nextLeafIndex);
    } else {
      this._updateMerkleHashes(indexToUpdate);
    }
  }

  public getProof(index: bigint, value: string): Proof {
    if (index >= this.getLevelNodesCount(LEAVES_LEVEL)) {
      throw new Error(`Leaf with index ${index} does not exist.`);
    }

    const siblings: string[] = [];
    const leafData: LeafData = this.leavesData[index.toString()];

    let leafExists: boolean;

    if (leafData.value == value) {
      leafExists = true;
    } else if (this._isLowLeaf(index, value)) {
      leafExists = false;
    } else {
      throw new Error(`Invalid index ${index} for the value ${value}`);
    }

    let currentIndex = index;

    for (let level = 0n; level < this.levelsCount - 1; level++) {
      const isRightChild = currentIndex % 2n !== 0n;
      const siblingIndex = isRightChild ? currentIndex - 1n : currentIndex + 1n;

      let siblingHash: string;

      if (siblingIndex < this.getLevelNodesCount(level)) {
        siblingHash = this.levels[level.toString()][siblingIndex.toString()];
      } else {
        siblingHash = this.zeroHashesCache[Number(level)];
      }

      siblings.push(siblingHash);

      currentIndex = currentIndex / 2n;
    }

    return {
      root: this.getRoot(),
      siblings: siblings,
      existence: leafExists,
      index: index,
      value: leafData.value,
      nextLeafIndex: leafData.nextLeafIndex,
    };
  }

  public verifyProof(proof: Proof): boolean {
    return this.processProof(proof) == this.getRoot();
  }

  public processProof(proof: Proof): string {
    let computedHash = this.hashLeafFn({
      index: proof.index,
      nextIndex: proof.nextLeafIndex,
      value: proof.value,
      isActive: true,
    });

    for (let i = 0; i < proof.siblings.length; ++i) {
      if (((proof.index >> BigInt(i)) & 1n) === 1n) {
        computedHash = this.hashNodeFn(proof.siblings[i], computedHash);
      } else {
        computedHash = this.hashNodeFn(computedHash, proof.siblings[i]);
      }
    }

    return computedHash;
  }

  public getLeafData(index: bigint): LeafData {
    if (index >= this.getLevelNodesCount(LEAVES_LEVEL)) {
      throw new Error(`Leaf with index ${index} does not exist.`);
    }

    return this.leavesData[index.toString()];
  }

  public getPrevLeafIndex(index: bigint): bigint {
    const leavesCount = this.getLevelNodesCount(LEAVES_LEVEL);
    let currentIndex = ZERO_IDX;

    for (let i = 0n; i < leavesCount; i++) {
      const currentLeafData = this.getLeafData(currentIndex);
      if (currentLeafData.nextLeafIndex == index) {
        return currentIndex;
      }

      currentIndex = currentLeafData.nextLeafIndex;
    }

    throw new Error(`Can't find a previous leaf for the leaf with index ${index}`);
  }

  public getLeafIndex(value: string): bigint {
    const leavesCount = this.getLevelNodesCount(LEAVES_LEVEL);

    for (let i = 0n; i < leavesCount; i++) {
      if (this._cmpValues(this.leavesData[i.toString()].value, value) == 0) {
        return i;
      }
    }

    throw new Error(`Can't find a leaf with value ${value}`);
  }

  public getLowLeafIndex(value: string): bigint {
    const leavesCount = this.getLevelNodesCount(LEAVES_LEVEL);

    for (let i = 0n; i < leavesCount; i++) {
      if (this._isLowLeaf(i, value)) {
        return i;
      }
    }

    throw new Error("Can't find a low leaf index");
  }

  public getRoot(): string {
    return this.levels[this.levelsCount - 1][0];
  }

  public getLevelsCount(): number {
    return this.levelsCount;
  }

  public getLevelHashes(level: bigint): string[] {
    return Object.values(this.levels[level.toString()]) || [];
  }

  public getLevelNodesCount(level: bigint): bigint {
    return BigInt(Object.values(this.levels[level.toString()]).length);
  }

  public getLeavesCount(): bigint {
    return this.getLevelNodesCount(LEAVES_LEVEL);
  }

  private _updateNextLeafIndex(leafIndex: bigint, newNextLeafIndex: bigint): void {
    this.leavesData[leafIndex.toString()].nextLeafIndex = newNextLeafIndex;

    this._updateMerkleHashes(leafIndex);
  }

  private _updateMerkleHashes(leafIndex: bigint): void {
    let levelIndex: bigint = leafIndex;

    for (let level = 0n; level < this.levelsCount; level++) {
      let currentLevelNodeHash: string;

      if (level == LEAVES_LEVEL) {
        const leafData = this.getLeafData(levelIndex);

        currentLevelNodeHash = this.hashLeafFn({
          index: levelIndex,
          value: leafData.value,
          nextIndex: leafData.nextLeafIndex,
          isActive: true,
        });
      } else {
        currentLevelNodeHash = this._calculateNodeHash(levelIndex, level);
      }

      this.levels[level.toString()][levelIndex.toString()] = currentLevelNodeHash;

      levelIndex /= 2n;
    }
  }

  private _pushLeaf(leafIndex: bigint, leafData: LeafData) {
    this.leavesData[leafIndex.toString()] = leafData;

    let levelIndex = leafIndex;

    for (let level = 0n; level < this.levelsCount; level++) {
      let currentLevelNodeHash: string;

      if (level == LEAVES_LEVEL) {
        currentLevelNodeHash = this.hashLeafFn({
          index: levelIndex,
          value: leafData.value,
          nextIndex: leafData.nextLeafIndex,
          isActive: true,
        });
      } else {
        currentLevelNodeHash = this._calculateNodeHash(levelIndex, level);
      }

      this.levels[level.toString()][levelIndex.toString()] = currentLevelNodeHash;

      if (level + 1n == BigInt(this.levelsCount) && this.getLevelNodesCount(level) > 1) {
        this.levelsCount++;
      }

      levelIndex /= 2n;
    }
  }

  private _precalculateZeroHashes(maxDepth: number): void {
    if (this.zeroHashesCache.length > 0) return;

    let currentHash = this.hashLeafFn({
      index: ZERO_IDX,
      value: encodeBytes32Value(0n),
      nextIndex: ZERO_IDX,
      isActive: false,
    });
    this.zeroHashesCache.push(currentHash);

    for (let i = 1; i <= maxDepth; i++) {
      currentHash = this.hashNodeFn(currentHash, currentHash);
      this.zeroHashesCache.push(currentHash);
    }
  }

  private _createLeafLevel(leavesData: IndexedLeafData[]): string[] {
    return leavesData.map((data, index) => {
      this.leavesData[index.toString()] = {
        value: data.value,
        nextLeafIndex: data.nextIndex,
      };

      return this.hashLeafFn(data);
    });
  }

  private _buildTree(leavesData: IndexedLeafData[]): void {
    let currentLevelHashes = this._createLeafLevel(leavesData);

    currentLevelHashes.forEach((leafHash: string, index: number) => {
      this.levels[LEAVES_LEVEL.toString()][index] = leafHash;
    });

    let level = 0;

    while (currentLevelHashes.length > 1) {
      const nextLevelHashes: string[] = [];

      for (let i = 0; i < currentLevelHashes.length; i += 2) {
        const left = currentLevelHashes[i];
        const right = i + 1 < currentLevelHashes.length ? currentLevelHashes[i + 1] : this.zeroHashesCache[level];

        nextLevelHashes.push(this.hashNodeFn(left, right));
      }

      level++;

      nextLevelHashes.forEach((leafHash: string, index: number) => {
        this.levels[level.toString()][index] = leafHash;
      });

      currentLevelHashes = nextLevelHashes;
    }
  }

  private _calculateNodeHash(index: bigint, level: bigint): string {
    if (level == LEAVES_LEVEL) {
      throw new Error("Not a leaves level");
    }

    const childrenLevel = level - 1n;
    const leftChild = index * 2n;
    const rightChild = index * 2n + 1n;

    const leftChildHash = this.levels[childrenLevel.toString()][leftChild.toString()];
    const rightChildHash =
      rightChild < this.getLevelNodesCount(childrenLevel)
        ? this.levels[childrenLevel.toString()][rightChild.toString()]
        : this.zeroHashesCache[Number(childrenLevel)];

    return this.hashNodeFn(leftChildHash, rightChildHash);
  }

  private _isLowLeaf(index: bigint, value: string): boolean {
    const leafData = this.getLeafData(index);

    return (
      this._cmpValues(leafData.value, value) == -1 &&
      (leafData.nextLeafIndex == ZERO_IDX ||
        this._cmpValues(this.getLeafData(leafData.nextLeafIndex).value, value) == 1)
    );
  }

  private _cmpValues(value0: string, value1: string): number {
    if (BigInt(value0) > BigInt(value1)) {
      return 1;
    } else if (BigInt(value0) < BigInt(value1)) {
      return -1;
    } else {
      return 0;
    }
  }
}
