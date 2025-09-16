import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { Schnorr256Mock } from "@ethers-v6";

import { AffinePoint } from "@noble/curves/abstract/curve";
import { bytesToNumberBE } from "@noble/curves/abstract/utils";
import { secp256k1 } from "@noble/curves/secp256k1";

const { ethers, networkHelpers } = await hre.network.connect();

describe("Schnorr256", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

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

  const schnorrAdaptorSign = function (hashedMessage: string, privKey: bigint, t: bigint) {
    const randomness = schnorrKeyPair();
    const k = randomness.privKey;
    const R = randomness.pubKey;

    const T = secp256k1.ProjectivePoint.BASE.multiply(t).toAffine();

    const RT = secp256k1.ProjectivePoint.fromAffine(R).add(secp256k1.ProjectivePoint.fromAffine(T)).toAffine();

    const c = BigInt(
      ethers.solidityPackedKeccak256(
        ["uint256", "uint256", "uint256", "uint256", "bytes32"],
        [secp256k1.CURVE.Gx, secp256k1.CURVE.Gy, RT.x, RT.y, hashedMessage],
      ),
    );

    const e = (k + c * privKey + t) % secp256k1.CURVE.n;

    const signature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [R.x, R.y, e]);

    return { signature, T };
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

  let schnorr: Schnorr256Mock;

  before("setup", async () => {
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

  describe("verifyAdaptor", () => {
    it("should verify the adaptor signature", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const hashedMessage = ethers.keccak256("0x1337");

      const t = bytesToNumberBE(secp256k1.utils.randomPrivateKey());

      const { signature, T } = schnorrAdaptorSign(hashedMessage, privKey, t);

      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, signature, serializePoint(pubKey), T)).to.be.true;
    });

    it("should not verify if adaptor signature, public key or T is invalid", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const hashedMessage = ethers.keccak256("0x1337");

      const t = bytesToNumberBE(secp256k1.utils.randomPrivateKey());

      const { signature, T } = schnorrAdaptorSign(hashedMessage, privKey, t);

      const r = signature.slice(2, 130);
      const e = signature.slice(130);

      const wrongSig1 = "0x" + ethers.toBeHex(0, 0x40).slice(2) + e;
      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, wrongSig1, serializePoint(pubKey), T)).to.be.false;

      const wrongSig2 = "0x" + r + ethers.toBeHex((1n << 256n) - 1n, 0x20).slice(2);
      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, wrongSig2, serializePoint(pubKey), T)).to.be.false;

      const wrongPubKey = "0x" + ethers.toBeHex(0, 0x40).slice(2);
      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, signature, wrongPubKey, T)).to.be.false;

      let invalidT = { x: 0n, y: 0n };
      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, signature, serializePoint(pubKey), invalidT)).to.be
        .false;

      invalidT = { x: 1n << 255n, y: 1n << 255n };
      expect(await schnorr.verifyAdaptorSECP256k1(hashedMessage, signature, serializePoint(pubKey), invalidT)).to.be
        .false;
    });
  });
});
