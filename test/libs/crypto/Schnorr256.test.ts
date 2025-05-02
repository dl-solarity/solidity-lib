import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { Schnorr256Mock } from "@ethers-v6";

import { secp256k1 } from "@noble/curves/secp256k1";
import { bytesToNumberBE } from "@noble/curves/abstract/utils";
import { AffinePoint } from "@noble/curves/abstract/curve";

describe("Schnorr256", () => {
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

  const prepareParameters = function (message: string) {
    const { privKey, pubKey } = schnorrKeyPair();

    const hashedMessage = ethers.keccak256(message);

    const signature = schnorrSign(hashedMessage, privKey);

    return {
      hashedMessage,
      signature,
      pubKey: serializePoint(pubKey),
    };
  };

  const reverter = new Reverter();

  let schnorr: Schnorr256Mock;

  before(async () => {
    const Schnorr256 = await ethers.getContractFactory("Schnorr256Mock");

    schnorr = await Schnorr256.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("verify", () => {
    it("should verify the signature", async () => {
      const { hashedMessage, signature, pubKey } = prepareParameters("0x1337");

      expect(await schnorr.verifySECP256k1(hashedMessage, signature, pubKey)).to.be.true;
    });

    it("should revert if signature or public key has an invalid length", async () => {
      const { hashedMessage, signature, pubKey } = prepareParameters("0x1337");

      const wrongSig = "0x0101";

      await expect(schnorr.verifySECP256k1(hashedMessage, wrongSig, pubKey)).to.be.revertedWithCustomError(
        schnorr,
        "LengthIsNot96",
      );

      const wrongPubKey = "0x0101";

      await expect(schnorr.verifySECP256k1(hashedMessage, signature, wrongPubKey)).to.be.revertedWithCustomError(
        schnorr,
        "LengthIsNot64",
      );
    });

    it("should not verify if signature or public key is invalid", async () => {
      const { hashedMessage, signature, pubKey } = prepareParameters("0x1337");

      const r = signature.slice(2, 130);
      const e = signature.slice(130);

      const wrongSig1 = "0x" + ethers.toBeHex(0, 0x40).slice(2) + e;
      expect(await schnorr.verifySECP256k1(hashedMessage, wrongSig1, pubKey)).to.be.false;

      const wrongSig2 = "0x" + r + ethers.toBeHex((1n << 256n) - 1n, 0x20).slice(2);
      expect(await schnorr.verifySECP256k1(hashedMessage, wrongSig2, pubKey)).to.be.false;

      const wrongPubKey = "0x" + ethers.toBeHex(0, 0x40).slice(2);
      expect(await schnorr.verifySECP256k1(hashedMessage, signature, wrongPubKey)).to.be.false;
    });
  });
});
