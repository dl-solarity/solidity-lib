import { BaseContract, ContractFactory, hexlify, toBeHex } from "ethers";

import type { HardhatEthers } from "@nomicfoundation/hardhat-ethers/types";

import { Poseidon } from "@iden3/js-crypto";
// @ts-ignore
import { poseidonContract } from "circomlibjs";

export async function getPoseidon(ethers: HardhatEthers, num: number): Promise<BaseContract> {
  if (num < 1 || num > 6) {
    throw new Error("Poseidon Hash: Invalid number");
  }

  const [deployer] = await ethers.getSigners();
  const PoseidonHasher = new ContractFactory(
    poseidonContract.generateABI(num),
    poseidonContract.createCode(num),
    deployer,
  );
  const poseidonHasher = await PoseidonHasher.deploy();
  await poseidonHasher.waitForDeployment();

  return poseidonHasher;
}

export function poseidonHash(data: string): string {
  data = hexlify(data);

  const chunks = splitHexIntoChunks(data.replace("0x", ""), 64);
  const inputs = chunks.map((v) => BigInt(v));

  return toBeHex(Poseidon.hash(inputs), 32);
}

function splitHexIntoChunks(hexString: string, chunkSize = 64) {
  const regex = new RegExp(`.{1,${chunkSize}}`, "g");
  const chunks = hexString.match(regex);

  if (!chunks) {
    throw new Error("Invalid hex string");
  }

  return chunks.map((chunk) => "0x" + chunk);
}
