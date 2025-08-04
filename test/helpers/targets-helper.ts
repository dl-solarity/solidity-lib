export const DIFFICULTY_ADJUSTMENT_INTERVAL = 2016;
export const INITIAL_TARGET = "0x00000000ffff0000000000000000000000000000000000000000000000000000";

export function bitsToTarget(bitsStr: string): string {
  const bits = BigInt(bitsStr);
  const exponent = (bits >> 24n) & 0xffn;
  const mantissa = bits & 0xffffffn;

  let target: bigint;

  if (exponent <= 3n) {
    target = mantissa >> (8n * (3n - exponent));
  } else {
    target = mantissa << (8n * (exponent - 3n));
  }

  return `0x${target.toString(16).padStart(64, "0")}`;
}

export function targetToBits(targetSrt: string) {
  const target = BigInt(targetSrt);
  let exponent = 0n;
  let tmp = target;

  while (tmp > 0xffffffn) {
    tmp >>= 8n;
    exponent += 1n;
  }

  let mantissa = target >> (8n * exponent);
  exponent += 3n;

  // If the highest bit is set, shift mantissa and increment exponent
  if (mantissa & 0x800000n) {
    mantissa >>= 8n;
    exponent += 1n;
  }

  const bits = (exponent << 24n) | (mantissa & 0xffffffn);
  return `0x${bits.toString(16)}`;
}

export function calculateWork(targetHex: string) {
  const target = BigInt(targetHex);
  const maxTarget = (1n << 256n) - 1n;
  return maxTarget / (target + 1n);
}
