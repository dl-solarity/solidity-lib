import { ethers } from "hardhat";

export function wei(value: string | number | bigint, decimal: number = 18): bigint {
  if (typeof value == "number" || typeof value == "bigint") {
    value = value.toString();
  }

  return ethers.parseUnits(value as string, decimal);
}

export function fromWei(value: string | number | bigint, decimal: number = 18): string {
  return (BigInt(value) / 10n ** BigInt(decimal)).toString();
}
