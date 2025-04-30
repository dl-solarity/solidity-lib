import { ethers } from "hardhat";
import { Reverter } from "@/test/helpers/reverter";

import { SchnorrSignatureMock } from "@ethers-v6";

import { secp256k1 } from "@noble/curves/secp256k1";
import { bytesToNumberBE } from "@noble/curves/abstract/utils";
import { AffinePoint } from "@noble/curves/abstract/curve";

describe.only("SchnorrSignature", () => {
  const schnorrKeyPair = () => {
    const privKey = bytesToNumberBE(secp256k1.utils.randomPrivateKey());
    const pubKey = secp256k1.ProjectivePoint.BASE.multiply(privKey).toAffine();

    return { privKey, pubKey };
  };

  const serializePoint = (p: AffinePoint<bigint>) => {
    return ethers.solidityPacked(["uint256", "uint256"], [p.x, p.y]);
  };

  const schnorrSign = function (hashedMessage: string, privKey: bigint) {
    const randomness = schnorrKeyPair();
    const k = randomness.privKey;
    const R = randomness.pubKey;

    const c = BigInt(
      ethers.solidityPackedKeccak256(
        ["uint256", "uint256", "uint256", "uint256", "bytes32"],
        [secp256k1.CURVE.Gx, secp256k1.CURVE.Gy, R.x, R.y, hashedMessage],
      ),
    );
    const e = (k + c * privKey) % secp256k1.CURVE.n;

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

      console.log(await schnorr.verifySECP256k1(hashedMessage, signature, pubKeyBytes));
    });
  });
});
