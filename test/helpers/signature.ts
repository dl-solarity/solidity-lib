import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";
import { HardhatEthers } from "@nomicfoundation/hardhat-ethers/types";

export async function getSignature(ethers: HardhatEthers, account: HardhatEthersSigner, message: string) {
  return ethers.provider.send("eth_sign", [await account.getAddress(), message]);
}
