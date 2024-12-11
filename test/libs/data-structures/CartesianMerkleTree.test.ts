import { expect } from "chai";
import { ethers } from "hardhat";
import { BytesLike } from "ethers";

import { CartesianMerkleTreeMock } from "@ethers-v6";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { ZERO_BYTES32 } from "@/scripts/utils/constants";
import { getPoseidon, poseidonHash } from "@/test/helpers/poseidon-hash";

import { CartesianMerkleTree } from "@/generated-types/ethers/contracts/mock/libs/data-structures/CartesianMerkleTreeMock";

describe("CartesianMerkleTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;

  let treap: CartesianMerkleTreeMock;

  function createRandomArray(length: number, bytesCount: number = 32): string[] {
    const resultArr: string[] = [];

    for (let i = 0; i < length; i++) {
      resultArr.push(ethers.hexlify(ethers.randomBytes(bytesCount)));
    }

    return resultArr;
  }

  async function verifyCMTProof(
    proof: CartesianMerkleTree.ProofStruct,
    expectedRoot: string,
    keyToVerify: string,
    expectedExistence: boolean = true,
    isPoseidonHash: boolean = false,
  ) {
    expect(proof.existence).to.be.eq(expectedExistence);

    keyToVerify = `0x${keyToVerify.slice(2).padStart(64, "0")}`;

    keyToVerify = proof.existence ? keyToVerify.toString() : proof.nonExistenceKey.toString();

    let currentSiblingsIndex: number = Number(proof.siblingsLength);
    let finalHash: string = "";

    while (true) {
      let valuesToHash: string[] = [];
      let currentSiblings: BytesLike[] = proof.siblings.slice(currentSiblingsIndex - 2, currentSiblingsIndex);

      if (currentSiblingsIndex === Number(proof.siblingsLength)) {
        if (BigInt(ethers.hexlify(currentSiblings[0])) > BigInt(ethers.hexlify(currentSiblings[1]))) {
          currentSiblings = [currentSiblings[1], currentSiblings[0]];
        }

        valuesToHash = [keyToVerify, ethers.hexlify(currentSiblings[0]), ethers.hexlify(currentSiblings[1])];
      } else {
        let sortedChildren: string[] = [finalHash, ethers.hexlify(currentSiblings[1])];

        if (BigInt(sortedChildren[0]) > BigInt(sortedChildren[1])) {
          sortedChildren = [sortedChildren[1], sortedChildren[0]];
        }

        valuesToHash = [currentSiblings[0].toString(), sortedChildren[0], sortedChildren[1]];
      }

      let nodeHash: string = "";

      if (isPoseidonHash) {
        nodeHash = await treap.hash3(valuesToHash[0], valuesToHash[1], valuesToHash[2]);
      } else {
        nodeHash = ethers.solidityPackedKeccak256(["bytes32", "bytes32", "bytes32"], valuesToHash);
      }

      finalHash = nodeHash;
      currentSiblingsIndex -= 2;

      if (currentSiblingsIndex <= 0) {
        break;
      }
    }

    expect(expectedRoot).to.be.eq(finalHash);
  }

  function shuffle(array: any): any {
    let currentIndex = array.length;

    while (currentIndex != 0) {
      let randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;

      [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }
  }

  before("setup", async () => {
    [USER1] = await ethers.getSigners();

    const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
      libraries: {
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
      },
    });

    treap = await CartesianMerkleTreeMock.deploy();

    await reverter.snapshot();
  });

  afterEach("cleanup", async () => {
    await reverter.revert();
  });

  describe("Uint CMT", () => {
    beforeEach("setup", async () => {
      await treap.initializeUintTreap(40);
      await treap.setUintPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treap.initializeUintTreap(20)).to.be.rejectedWith(
        "CartesianMerkleTree: treap is already initialized",
      );
    });

    it("should revert if trying to set incorrect desired proof size", async () => {
      await expect(treap.setDesiredProofSizeUintTreap(0)).to.be.rejectedWith(
        "CartesianMerkleTree: desired proof size must be greater than zero",
      );
    });

    it("should correctly set new desired proof size", async () => {
      await treap.setDesiredProofSizeUintTreap(20);

      expect(await treap.getUintDesiredProofSize()).to.equal(20);
    });

    it("should revert if trying to call add/remove functions on non-initialized treap", async () => {
      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const newTreap = await CartesianMerkleTreeMock.deploy();

      await expect(newTreap.addUint(13n)).to.be.rejectedWith("CartesianMerkleTree: treap is not initialized");
      await expect(newTreap.removeUint(13n)).to.be.rejectedWith("CartesianMerkleTree: treap is not initialized");
    });

    it("should add and full remove elements from the CMT correctly", async () => {
      const keysCount: number = 20;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treap.addUint(keys[i]);
      }

      shuffle(keys);

      for (let i = 0; i < keysCount; i++) {
        await treap.removeUint(keys[i]);
      }

      expect(await treap.getUintRoot()).to.equal(ZERO_BYTES32);

      expect(await treap.getUintNodesCount()).to.equal(0);

      expect(await treap.isUintCustomHasherSet()).to.be.true;
      expect(treap.setUintPoseidonHasher()).to.not.be.rejected;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();
        await tmpTreap.initializeUintTreap(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreap.addUint(keys[i]);
        }

        if (i == 0) {
          treapRoot = await tmpTreap.getUintRoot();
        }

        expect(treapRoot).to.be.eq(await tmpTreap.getUintRoot());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treap.addUint(keys[i]);
      }

      const treapRoot: string = await treap.getUintRoot();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treap.getUintNodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        let currentNode = await treap.getUintNode(randIndex);

        await treap.removeUint(currentNode.key);

        expect(await treap.getUintRoot()).to.be.not.eq(treapRoot);

        await treap.addUint(currentNode.key);

        expect(await treap.getUintRoot()).to.be.eq(treapRoot);
      }
    });

    it("should not remove non-existent leaves", async () => {
      const keys = [7n, 1n, 5n];

      for (let key of keys) {
        const hexKey = ethers.toBeHex(key, 32);

        await treap.addUint(hexKey);
      }

      await expect(treap.removeUint(ethers.toBeHex(8, 32))).to.be.revertedWith(
        "CartesianMerkleTree: the node does not exist",
      );
    });

    it("should generate empty proof on empty tree", async () => {
      const desiredProofSize = 20;
      const proof = await treap.getUintProof(ethers.toBeHex(1n, 32), desiredProofSize);

      expect(proof.siblingsLength).to.be.eq(0);
      expect(proof.siblings).to.be.deep.eq(new Array(desiredProofSize).fill(0));
      expect(proof.existence).to.be.false;
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treap.addUint(keys[i]);
      }

      const treapRoot: string = await treap.getUintRoot();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treap.getUintNodesCount()) - 1)) + 1;
        const proof = await treap.getUintProof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapRoot, keys[randIndex], true, true);
      }
    });

    it("should generate correct proof for the non-existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treap.addUint(keys[i]);
      }

      const desiredProofSize = 50;

      await treap.setDesiredProofSizeUintTreap(desiredProofSize);

      const treapRoot: string = await treap.getUintRoot();

      for (let i = 0; i < keysCount; i++) {
        const randKey = ethers.hexlify(ethers.randomBytes(32));
        const proof = await treap.getUintProof(randKey, 0);

        expect(proof.siblings.length).to.be.eq(desiredProofSize);

        await verifyCMTProof(proof, treapRoot, randKey, false, true);
      }
    });

    it("should revert if trying to add/remove zero key", async () => {
      const reason = "CartesianMerkleTree: the key can't be zero";

      await expect(treap.addUint(ZERO_BYTES32)).to.be.rejectedWith(reason);
      await expect(treap.removeUint(ZERO_BYTES32)).to.be.rejectedWith(reason);
    });

    it("should revert if trying to set hasher with non-empty treap", async () => {
      const key = poseidonHash(ethers.toBeHex(2341n));

      await treap.addUint(key);

      await expect(treap.setUintPoseidonHasher()).to.be.rejectedWith("CartesianMerkleTree: treap is not empty");
    });

    it("should revert if trying to add a node with the same key", async () => {
      const key = poseidonHash(ethers.toBeHex(2341n));

      await treap.addUint(key);

      await expect(treap.addUint(key)).to.be.rejectedWith("CartesianMerkleTree: the key already exists");
    });

    it("should get empty Node by non-existing key", async () => {
      expect((await treap.getUintNodeByKey(1n)).key).to.be.equal(ZERO_BYTES32);

      await treap.addUint(ethers.toBeHex(7n, 32));

      expect((await treap.getUintNodeByKey(5n)).key).to.be.equal(ZERO_BYTES32);
    });

    it("should get exception if desired size is too low", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treap.addUint(keys[i]);
      }

      await expect(treap.getUintProof(keys[0], 1)).to.be.rejectedWith(
        "CartesianMerkleTree: desired proof size is too low",
      );
    });
  });

  describe("Bytes32 CMT", () => {
    beforeEach("setup", async () => {
      await treap.initializeBytes32Treap(15);
      await treap.setBytes32PoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treap.initializeBytes32Treap(20)).to.be.rejectedWith(
        "CartesianMerkleTree: treap is already initialized",
      );
    });

    it("should correctly set new desired proof size", async () => {
      await treap.setDesiredProofSizeBytes32Treap(20);

      expect(await treap.getBytes32DesiredProofSize()).to.equal(20);
    });

    it("should build a Cartesian Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const key = poseidonHash(ethers.toBeHex(ethers.hexlify(ethers.randomBytes(28)), 32));

        await treap.addBytes32(key);

        expect((await treap.getBytes32NodeByKey(key)).key).to.be.eq(BigInt(key));

        const proof = await treap.getBytes32Proof(key, 35);
        await verifyCMTProof(proof, await treap.getBytes32Root(), key, true, true);
      }

      expect(await treap.isBytes32CustomHasherSet()).to.be.true;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();
        await tmpTreap.initializeBytes32Treap(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreap.addBytes32(keys[i]);
        }

        if (i == 0) {
          treapRoot = await tmpTreap.getBytes32Root();
        }

        expect(treapRoot).to.be.eq(await tmpTreap.getBytes32Root());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keysCount; i++) {
        await treap.addBytes32(keys[i]);
      }

      const treapRoot: string = await treap.getBytes32Root();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treap.getBytes32NodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        let currentNode = await treap.getBytes32Node(randIndex);

        await treap.removeBytes32(currentNode.key);

        expect(await treap.getBytes32Root()).to.be.not.eq(treapRoot);

        await treap.addBytes32(currentNode.key);

        expect(await treap.getBytes32Root()).to.be.eq(treapRoot);
      }
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount);

      for (let i = 0; i < keys.length; i++) {
        await treap.addBytes32(keys[i]);
      }

      const treapRoot: string = await treap.getBytes32Root();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treap.getBytes32NodesCount()) - 1)) + 1;
        const proof = await treap.getBytes32Proof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapRoot, keys[randIndex], true, true);
      }
    });
  });

  describe("Address CMT", () => {
    beforeEach("setup", async () => {
      await treap.initializeAddressTreap(15);
      await treap.setAddressPoseidonHasher();
    });

    it("should not initialize twice", async () => {
      await expect(treap.initializeAddressTreap(20)).to.be.rejectedWith(
        "CartesianMerkleTree: treap is already initialized",
      );
    });

    it("should correctly set new desired proof size", async () => {
      await treap.setDesiredProofSizeAddressTreap(20);

      expect(await treap.getAddressDesiredProofSize()).to.equal(20);
    });

    it("should build a Cartesian Merkle Tree correctly with multiple elements", async () => {
      for (let i = 1n; i < 20n; i++) {
        const key = ethers.toBeHex(BigInt(await USER1.getAddress()) + i);

        await treap.addAddress(key);

        expect((await treap.getAddressNodeByKey(key)).key).to.be.eq(BigInt(key));

        const proof = await treap.getAddressProof(key, 35);
        await verifyCMTProof(proof, await treap.getAddressRoot(), key, true, true);
      }

      expect(await treap.isAddressCustomHasherSet()).to.be.true;
    });

    it("should maintain deterministic property", async () => {
      const keysCount: number = 100;
      const keys: string[] = createRandomArray(keysCount, 20);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();
        await tmpTreap.initializeAddressTreap(40);

        for (let i = 0; i < keysCount; i++) {
          await tmpTreap.addAddress(keys[i]);
        }

        if (i == 0) {
          treapRoot = await tmpTreap.getAddressRoot();
        }

        expect(treapRoot).to.be.eq(await tmpTreap.getAddressRoot());

        shuffle(keys);
      }
    });

    it("should maintain idempotence", async () => {
      const keysCount: number = 30;
      const keys: string[] = createRandomArray(keysCount, 20);

      for (let i = 0; i < keysCount; i++) {
        await treap.addAddress(keys[i]);
      }

      const treapRoot: string = await treap.getAddressRoot();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 10; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treap.getAddressNodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }
        let currentNode = await treap.getAddressNode(randIndex);
        const currentNodeKey = `0x${currentNode.key.slice(26)}`;

        await treap.removeAddress(currentNodeKey);

        expect(await treap.getAddressRoot()).to.be.not.eq(treapRoot);

        await treap.addAddress(currentNodeKey);

        expect(await treap.getAddressRoot()).to.be.eq(treapRoot);
      }
    });

    it("should generate correct proof for the existing nodes", async () => {
      const keysCount: number = 50;
      const keys: string[] = createRandomArray(keysCount, 20);

      for (let i = 0; i < keys.length; i++) {
        await treap.addAddress(keys[i]);
      }

      const treapRoot: string = await treap.getAddressRoot();

      for (let i = 0; i < keysCount; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treap.getAddressNodesCount()) - 1)) + 1;
        const proof = await treap.getAddressProof(keys[randIndex], 40);

        await verifyCMTProof(proof, treapRoot, keys[randIndex], true, true);
      }
    });
  });
});
