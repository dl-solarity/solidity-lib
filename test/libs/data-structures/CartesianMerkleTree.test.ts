import { expect } from "chai";
import { ethers } from "hardhat";

import { CartesianMerkleTreeMock } from "@ethers-v6";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getPoseidon } from "@/test/helpers/poseidon-hash";

describe.only("CartesianMerkleTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;

  let treap: CartesianMerkleTreeMock;

  function createRandomArray(length: number): string[] {
    const resultArr: string[] = [];

    for (let i = 0; i < length; i++) {
      resultArr.push(ethers.hexlify(ethers.randomBytes(32)));
    }

    return resultArr;
  }

  async function verifyCMTProof(
    cmt: CartesianMerkleTreeMock,
    keyToVerify: string,
    expectedExistence: boolean = true,
    desiredProofSize = 40,
  ) {
    const proof = await cmt.proofUintV2(keyToVerify, desiredProofSize);

    expect(proof.existence).to.be.eq(expectedExistence);

    keyToVerify = proof.existence ? keyToVerify : proof.nonExistenceKey;

    let currentSiblingsIndex: number = Number(proof.siblingsLength);
    let finalHash: string = "";

    while (true) {
      let valuesToHash: string[] = [];
      let currentSiblings: string[] = proof.siblings.slice(currentSiblingsIndex - 2, currentSiblingsIndex);

      if (currentSiblingsIndex === Number(proof.siblingsLength)) {
        if (BigInt(currentSiblings[0]) > BigInt(currentSiblings[1])) {
          currentSiblings = [currentSiblings[1], currentSiblings[0]];
        }

        valuesToHash = [keyToVerify, currentSiblings[0], currentSiblings[1]];
      } else {
        let sortedChilds: string[] = [finalHash, currentSiblings[1]];

        if (BigInt(sortedChilds[0]) > BigInt(sortedChilds[1])) {
          sortedChilds = [sortedChilds[1], sortedChilds[0]];
        }

        valuesToHash = [currentSiblings[0], sortedChilds[0], sortedChilds[1]];
      }

      const nodeHash: string = ethers.solidityPackedKeccak256(["bytes32", "bytes32", "bytes32"], valuesToHash);

      finalHash = nodeHash;
      currentSiblingsIndex -= 2;

      if (currentSiblingsIndex <= 0) {
        break;
      }
    }

    expect(await cmt.getRootUintV2()).to.be.eq(finalHash);
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

  describe("property checks", () => {
    it("should have deterministic property", async () => {
      const randomElements: string[] = createRandomArray(500);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      let treapRoot: string = "";

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();

        for (let i = 0; i < randomElements.length; i++) {
          await tmpTreap.insertUint(randomElements[i]);
          await tmpTreap.insertUintV2(randomElements[i]);
        }

        if (i == 0) {
          treapRoot = await tmpTreap.getRootUint();
        }

        expect(treapRoot).to.be.eq(await tmpTreap.getRootUint());
        expect(treapRoot).to.be.eq(await tmpTreap.getRootUintV2());

        shuffle(randomElements);
      }
    });

    it("should have idempotent property", async () => {
      const randomElements: string[] = createRandomArray(100);

      for (let i = 0; i < randomElements.length; i++) {
        await treap.insertUint(randomElements[i]);
        await treap.insertUintV2(randomElements[i]);
      }

      const treapRoot: string = await treap.getRootUintV2();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 5; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treap.getNodesCountUintV2()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        let currentNode = await treap.getNodeUint(randIndex);
        let currentNodeV2 = await treap.getNodeUintV2(randIndex);

        await treap.removeUint(currentNode.key);
        await treap.removeUintV2(currentNodeV2.key);

        expect(await treap.getRootUint()).to.be.not.eq(treapRoot);
        expect(await treap.getRootUintV2()).to.be.not.eq(treapRoot);

        await treap.insertUint(currentNode.key);
        await treap.insertUintV2(currentNodeV2.key);

        expect(await treap.getRootUint()).to.be.eq(treapRoot);
        expect(await treap.getRootUintV2()).to.be.eq(treapRoot);
      }
    });
  });

  describe.skip("SMT vs CMT gas comparison", () => {
    it("insert with keccak256 hash function", async () => {
      const randomElements: string[] = createRandomArray(500);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();
        const tmpSmt = await SparseMerkleTreeMock.deploy();

        await tmpSmt.initializeUintTree(80);

        for (let i = 0; i < randomElements.length; i++) {
          await tmpTreap.insertUint(randomElements[i]);
          await tmpTreap.insertUintV2(randomElements[i]);
          await tmpSmt.addUint(randomElements[i], randomElements[i]);
        }

        shuffle(randomElements);
      }
    });

    it("insert with poseidon hash function", async () => {
      const randomElements: string[] = createRandomArray(500);

      const CartesianMerkleTreeMock = await ethers.getContractFactory("CartesianMerkleTreeMock", {
        libraries: {
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });
      const SparseMerkleTreeMock = await ethers.getContractFactory("SparseMerkleTreeMock", {
        libraries: {
          PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
          PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        },
      });

      for (let i = 0; i < 5; i++) {
        const tmpTreap = await CartesianMerkleTreeMock.deploy();
        const tmpSmt = await SparseMerkleTreeMock.deploy();

        await tmpTreap.setUintPoseidonHasher();
        await tmpTreap.setUintPoseidonHasherV2();

        await tmpSmt.initializeUintTree(80);
        await tmpSmt.setUintPoseidonHasher();

        for (let i = 0; i < randomElements.length; i++) {
          await tmpTreap.insertUint(randomElements[i]);
          await tmpTreap.insertUintV2(randomElements[i]);
          await tmpSmt.addUint(randomElements[i], randomElements[i]);
        }

        shuffle(randomElements);
      }
    });
  });

  describe("getProof", () => {
    it("should generate correct proofs", async () => {
      const randomElements: string[] = createRandomArray(100);

      for (let i = 0; i < randomElements.length; i++) {
        await treap.insertUint(randomElements[i]);
        await treap.insertUintV2(randomElements[i]);
      }

      for (let i = 0; i < 100; i++) {
        const randIndex = Math.floor(Math.random() * (Number(await treap.getNodesCountUintV2()) - 1)) + 1;

        await verifyCMTProof(treap, randomElements[randIndex]);
      }
    });
  });
});
