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

  const schnorrSign = function (hashedMessage: string, privKey: bigint, pubKey: AffinePoint<bigint>) {
    const randomness = schnorrKeyPair();
    const k = randomness.privKey;
    const R = randomness.pubKey;

    const c = BigInt(
      ethers.solidityPackedKeccak256(
        ["uint256", "uint256", "uint256", "uint256", "bytes32"],
        [pubKey.x, pubKey.y, R.x, R.y, hashedMessage],
      ),
    );
    const e = (k + c * privKey) % secp256k1.CURVE.n;

    return ethers.solidityPacked(["uint256", "uint256", "uint256"], [R.x, R.y, e]);
  };

  const schnorrAdaptorSign = function (
    hashedMessage: string,
    privKey: bigint,
    pubKey: AffinePoint<bigint>,
    T: AffinePoint<bigint>,
  ) {
    const randomness = schnorrKeyPair();
    const k = randomness.privKey;
    const R = randomness.pubKey;

    const RT = secp256k1.ProjectivePoint.fromAffine(R).add(secp256k1.ProjectivePoint.fromAffine(T)).toAffine();

    const c = BigInt(
      ethers.solidityPackedKeccak256(
        ["uint256", "uint256", "uint256", "uint256", "bytes32"],
        [pubKey.x, pubKey.y, RT.x, RT.y, hashedMessage],
      ),
    );

    const e = (k + c * privKey) % secp256k1.CURVE.n;

    const signature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [R.x, R.y, e]);

    return { signature, RT, e };
  };

  const prepareParameters = function (message: string) {
    const { privKey, pubKey } = schnorrKeyPair();

    const hashedMessage = ethers.keccak256(message);

    const signature = schnorrSign(hashedMessage, privKey, pubKey);

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

  describe("adaptorVerify", () => {
    it("should verify the adaptor signature", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const hashedMessage = ethers.keccak256("0x1337");

      const t = bytesToNumberBE(secp256k1.utils.randomPrivateKey());
      const T = secp256k1.ProjectivePoint.BASE.multiply(t).toAffine();

      const { signature } = schnorrAdaptorSign(hashedMessage, privKey, pubKey, T);

      expect(await schnorr.adaptorVerifySECP256k1(hashedMessage, signature, serializePoint(pubKey), T)).to.be.true;
    });

    it("should not verify if adaptor signature or public key or T is invalid", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const hashedMessage = ethers.keccak256("0x1337");

      const t = bytesToNumberBE(secp256k1.utils.randomPrivateKey());
      const t2 = bytesToNumberBE(secp256k1.utils.randomPrivateKey());

      const T = secp256k1.ProjectivePoint.BASE.multiply(t).toAffine();
      const T2 = secp256k1.ProjectivePoint.BASE.multiply(t2).toAffine();

      const { signature } = schnorrAdaptorSign(hashedMessage, privKey, pubKey, T);

      expect(await schnorr.adaptorVerifySECP256k1(ethers.keccak256("0x1227"), signature, serializePoint(pubKey), T)).to
        .be.false;

      expect(await schnorr.adaptorVerifySECP256k1(hashedMessage, signature, serializePoint(pubKey), T2)).to.be.false;

      const wrongPubKey = "0x" + ethers.toBeHex(0, 0x40).slice(2);
      expect(await schnorr.adaptorVerifySECP256k1(hashedMessage, signature, wrongPubKey, T)).to.be.false;
    });
  });

  describe("extract", () => {
    it("should extract secret from two signatures correctly", async () => {
      const { privKey, pubKey } = schnorrKeyPair();

      const hashedMessage = ethers.keccak256("0x1337");

      const t = bytesToNumberBE(secp256k1.utils.randomPrivateKey());
      const T = secp256k1.ProjectivePoint.BASE.multiply(t).toAffine();

      const { signature: adaptorSignature, RT, e } = schnorrAdaptorSign(hashedMessage, privKey, pubKey, T);

      const signatureScalar = (e + t) % secp256k1.CURVE.n;

      const signature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [RT.x, RT.y, signatureScalar]);

      expect(await schnorr.extractSECP256k1(signature, adaptorSignature)).to.be.eq(t);
    });

    it("should revert if invalid signature or adaptor signature scalar is provided", async () => {
      const signature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [1n, 1n, 10n]);
      const adaptorSignature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [1n, 1n, 2n]);

      const invalidSignature = ethers.solidityPacked(["uint256", "uint256", "uint256"], [1n, 1n, secp256k1.CURVE.n]);
      const invalidAdaptorSignature = ethers.solidityPacked(
        ["uint256", "uint256", "uint256"],
        [1n, 1n, secp256k1.CURVE.n],
      );

      await expect(schnorr.extractSECP256k1(invalidSignature, adaptorSignature)).to.be.revertedWithCustomError(
        schnorr,
        "InvalidSignatureScalar",
      );
      await expect(schnorr.extractSECP256k1(signature, invalidAdaptorSignature)).to.be.revertedWithCustomError(
        schnorr,
        "InvalidSignatureScalar",
      );
    });
  });
});
