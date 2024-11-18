import { randomBytes } from "crypto";

export function getModifiedSigOrPubKey(isLeftPartModified: boolean, value: string): string {
  let signature = "0x";

  if (isLeftPartModified) {
    if (value != "0") {
      signature += value;
    }

    signature = signature.padEnd(98, "0");

    signature += randomBytes(48).toString("hex");
  } else {
    signature += randomBytes(48).toString("hex");

    if (value != "0") {
      signature += value;
    }

    signature = signature.padEnd(194, "0");
  }

  return signature;
}
