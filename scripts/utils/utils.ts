import { ethers } from "hardhat";
import { PRECISION } from "./constants";

export function wei(value: string | number | bigint, decimal: number = 18): bigint {
  if (typeof value == "number" || typeof value == "bigint") {
    value = value.toString();
  }

  return ethers.parseUnits(value as string, decimal);
}

export function fromWei(value: string | number | bigint, decimal: number = 18): bigint {
  return BigInt(value) / 10n ** BigInt(decimal);
}

export function precision(value: string | number | bigint): bigint {
  if (typeof value == "number" || typeof value == "bigint") {
    value = value.toString();
  }

  return ethers.parseUnits(value as string, 25);
}

export function fromPrecision(value: bigint): bigint {
  return BigInt(value) / PRECISION;
}
