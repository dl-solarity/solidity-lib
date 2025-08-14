import { BigNumberish } from "ethers";

export function addHexPrefix(str: string): string {
  return `0x${str}`;
}

export function reverseBytes(str: string) {
  if (str.slice(0, 2) == "0x") str = str.slice(2);

  return addHexPrefix(Buffer.from(str, "hex").reverse().toString("hex"));
}

export function reverseByte(byte: string): string {
  const binary = parseInt(byte, 16).toString(2);
  const padded = binary.padStart(8, "0");

  return padded.split("").reverse().join("");
}

export function reverseUint32(decimalNumber: BigNumberish): BigInt {
  const hex = decimalNumber.toString(16);
  const bytes4 = hex.padStart(8, "0");

  return BigInt(reverseBytes(bytes4));
}
