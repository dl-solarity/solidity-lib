import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";
import type { HardhatEthers } from "@nomicfoundation/hardhat-ethers/types";

export async function getSignature(ethers: HardhatEthers, account: HardhatEthersSigner, message: string) {
  return ethers.provider.send("eth_sign", [await account.getAddress(), message]);
}
