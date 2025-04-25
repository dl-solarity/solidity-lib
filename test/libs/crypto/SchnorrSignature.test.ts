import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { SchnorrSignatureMock } from "@ethers-v6";

import { bn254 } from "@noble/curves/bn254";
import { bytesToNumberBE } from "@noble/curves/abstract/utils";
import { AffinePoint } from "@noble/curves/abstract/curve";
import { hash } from "crypto";

describe.only("SchnorrSignature", () => {
  const schnorrKeyPair = () => {
    const privKey = bytesToNumberBE(bn254.utils.randomPrivateKey());
    const pubKey = bn254.G1.ProjectivePoint.BASE.multiply(privKey).toAffine();

    return { privKey, pubKey };
  };

  const serializePoint = (p: AffinePoint<bigint>) => {
    return ethers.solidityPacked(["uint256", "uint256"], [p.x, p.y]);
  };

  const schnorrSign = function (hashedMessage: string, privKey: bigint) {
    const randomness = schnorrKeyPair();
    const k = randomness.privKey;
    const R = randomness.pubKey;

    const c = BigInt(ethers.solidityPackedKeccak256(["uint256", "uint256", "bytes32"], [R.x, R.y, hashedMessage]));

    const e = bn254.fields.Fr.create(k + c * privKey);

    return ethers.solidityPacked(["uint256", "uint256", "uint256"], [R.x, R.y, e]);
  };

  const reverter = new Reverter();

  let schnorr: SchnorrSignatureMock;

  before(async () => {
    const SchnorrSignature = await ethers.getContractFactory("SchnorrSignatureMock");

    schnorr = await SchnorrSignature.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe.only("verify", () => {
    it.only("should verify the signature", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const message = "0x1337";
      const hashedMessage = ethers.keccak256(message);

      const signature = schnorrSign(hashedMessage, privKey);
      const pubKeyBytes = serializePoint(pubKey);

      console.log(await schnorr.verifySignature(hashedMessage, signature, pubKeyBytes));
    });
  });
});
