import { expect } from "chai";
import { ethers } from "hardhat";

import { CartesianMerkleTreeMock, SparseMerkleTreeMock } from "@ethers-v6";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getPoseidon, poseidonHash } from "@/test/helpers/poseidon-hash";

describe.only("CartesianMerkleTree", () => {
  const reverter = new Reverter();

  let USER1: SignerWithAddress;

  let treap: CartesianMerkleTreeMock;
  let smt: SparseMerkleTreeMock;

  type Node = {
    key: string;
    priority: string;
    left: string;
    right: string;
  };

  type Tree = {
    [nodeId: string]: Node;
  };

  function createRandomArray(length: number): string[] {
    const resultArr: string[] = [];

    for (let i = 0; i < length; i++) {
      resultArr.push(ethers.hexlify(ethers.randomBytes(32)));
    }

    return resultArr;
  }

  async function displayTreapTopDown(tree: Tree, rootId: string): Promise<void> {
    if (rootId === "0") {
      console.log("Tree is empty.");
      return;
    }

    const levelMap: { [level: number]: string[] } = {};

    async function traverse(nodeId: string, level: number): Promise<void> {
      if (nodeId === "0") {
        return;
      }

      const node = tree[nodeId];
      if (!node) {
        throw new Error(`Node with ID ${nodeId} not found in tree`);
      }

      if (!levelMap[level]) {
        levelMap[level] = [];
      }

      levelMap[level].push(`(${node.key}, ${node.priority})`);

      await traverse(node.left, level + 1);
      await traverse(node.right, level + 1);
    }

    await traverse(rootId, 0);

    // Format the output for visualization
    const maxLevel = Math.max(...Object.keys(levelMap).map(Number));

    for (let level = 0; level <= maxLevel; level++) {
      const nodes = levelMap[level] || [];
      const padding = " ".repeat(2 ** (maxLevel - level) - 1);
      console.log(padding + nodes.join(" ".repeat(2 ** (maxLevel - level + 1) - 1)));
    }
  }

  function shuffle(array: any): any {
    let currentIndex = array.length;

    // While there remain elements to shuffle...
    while (currentIndex != 0) {
      // Pick a remaining element...
      let randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;

      // And swap it with the current element.
      [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }
  }

  before("setup", async () => {
    [USER1] = await ethers.getSigners();

    // treap = await ethers.deployContract("CartesianMerkleTreeMock");

    await reverter.snapshot();
  });

  afterEach("cleanup", async () => {
    await reverter.revert();
  });

  describe.only("property checks", () => {
    it.only("should have deterministic property", async () => {
      const randomElements: string[] = createRandomArray(10000);

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

        // await tmpTreap.setUintPoseidonHasher();

        await tmpSmt.initializeUintTree(80);
        // await tmpSmt.setUintPoseidonHasher();

        for (let i = 0; i < randomElements.length; i++) {
          await tmpTreap.insertUint(randomElements[i]);
          await tmpSmt.addUint(randomElements[i], randomElements[i]);
        }

        shuffle(randomElements);
      }
    });

    it("should have idempotent property", async () => {
      const randomElements: string[] = createRandomArray(100);

      for (let i = 0; i < randomElements.length; i++) {
        await treap.insertUint(randomElements[i]);
      }

      const treapRoot: string = await treap.getRootUint();
      const usedIndexes: number[] = [];

      for (let i = 0; i < 100; i++) {
        let randIndex: number = -1;

        while (true) {
          const newRandIndex =
            Math.floor(Math.random() * (Number(await treap.getNodesCount()) + usedIndexes.length - 1)) + 1;

          if (!usedIndexes.includes(newRandIndex)) {
            randIndex = newRandIndex;
            usedIndexes.push(newRandIndex);

            break;
          }
        }

        // console.log(`${i}. Rand index - ${randIndex}`);

        const currentNode = await treap.getNode(randIndex);

        await treap.removeUint(currentNode.key);

        expect(await treap.getRootUint()).to.be.not.eq(treapRoot);

        await treap.insertUint(currentNode.key);

        expect(await treap.getRootUint()).to.be.eq(treapRoot);
      }
    });
  });

  describe("test", () => {
    it("test", async () => {
      // const values = [[2, 10], [10, 20], [5, 7], [15, 3], [1, 8]];
      // const values = [[2, 10], [5, 7], [15, 3], [4, 6]];
      const values = [
        [10, 40],
        [20, 15],
        [15, 20],
        [2, 13],
        [7, 18],
        [5, 30],
      ];
      shuffle(values);
      // console.log(values);

      for (let i = 0; i < values.length; i++) {
        await treap.insertUint(values[i][0], values[i][1]);
      }

      console.log(`Root - ${await treap.getRootNodeIdUint()}`);
      console.log(`Nodes Count - ${await treap.getNodesCount()}`);

      const tree: Tree = {};

      for (let i = 1; i <= values.length; i++) {
        const node = await treap.getNode(i);

        tree[i] = {
          key: Number(node.key).toString(),
          priority: Number(node.priority).toString(),
          left: node.childLeft.toString(),
          right: node.childRight.toString(),
        };

        console.log(`${i} - Merkle hash - ${node.merkleHash}`);
      }

      await displayTreapTopDown(tree, (await treap.getRootNodeIdUint()).toString());

      // const proof = await treap.proof(14, 20);

      // console.log(JSON.stringify(proof));

      // await treap.remove(5);

      // for (let i = 1; i <= values.length; i++) {
      //   const node = await treap.getNode(i);

      //   tree[i] = {
      //     key: Number(node.key).toString(),
      //     priority: Number(node.value).toString(),
      //     left: node.childLeft.toString(),
      //     right: node.childRight.toString(),
      //   }

      //   console.log(`${i} - Merkle hash - ${node.merkleHash}`);
      // }

      // await displayTreapTopDown(tree, (await treap.getTreeRootNodeId()).toString());
    });

    it("test2", async () => {
      const values = [
        [2, 10],
        [5, 7],
      ];

      for (let i = 0; i < values.length; i++) {
        await treap.insert(values[i][0], values[i][1]);
      }

      console.log(`Root - ${await treap.getTreeRootNodeId()}`);
      console.log(`Nodes Count - ${await treap.getNodesCount()}`);

      for (let i = 1; i <= values.length; i++) {
        const node = await treap.getNode(i);

        console.log(`${i} - ${node.merkleHash}`);
      }

      // const tree: Tree = {};

      // for (let i = 1; i <= values.length; i++) {
      //   const node = await treap.getNode(i);
      //   // console.log(`Node ${i} - ${}`);

      //   tree[i] = {
      //     key: Number(node.key).toString(),
      //     priority: Number(node.value).toString(),
      //     left: node.childLeft.toString(),
      //     right: node.childRight.toString(),
      //   }

      //   console.log(`${i} - Merkle hash - ${node.merkleHash}`);
      // }

      // await displayTreapTopDown(tree, (await treap.getTreeRootNodeId()).toString());
    });
  });
});
