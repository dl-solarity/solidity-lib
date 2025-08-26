import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

export async function getSignature(account: SignerWithAddress, message: string) {
  return ethers.provider.send("eth_sign", [await account.getAddress(), message]);
}
