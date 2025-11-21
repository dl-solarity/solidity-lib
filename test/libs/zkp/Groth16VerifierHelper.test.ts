import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import type { Groth16Verifier2Mock, Groth16Verifier3Mock, Groth16VerifierHelperMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("Groth16VerifierHelper", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let verifierHelper: Groth16VerifierHelperMock;
  let verifier2: Groth16Verifier2Mock;
  let verifier3: Groth16Verifier3Mock;

  const a: [number, number] = [10, 20];
  const b: [[number, number], [number, number]] = [
    [1, 2],
    [3, 4],
  ];
  const c: [number, number] = [30, 40];

  const proofPoints = { a, b, c };

  const pubSignals2 = [2, 4];
  const pubSignals3 = [3, 6, 9];

  before("setup", async () => {
    const Groth16VerifierHelperMock = await ethers.getContractFactory("Groth16VerifierHelperMock");
    const Groth16Verifier2Mock = await ethers.getContractFactory("Groth16Verifier2Mock");
    const Groth16Verifier3Mock = await ethers.getContractFactory("Groth16Verifier3Mock");

    verifierHelper = await Groth16VerifierHelperMock.deploy();

    verifier2 = await Groth16Verifier2Mock.deploy(true, pubSignals2);
    verifier3 = await Groth16Verifier3Mock.deploy(true, pubSignals3);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("verifyProof", () => {
    it("should correctly call verifyProof function", async () => {
      expect(
        await verifierHelper.verifyProofGroth16ProofStruct(await verifier3.getAddress(), {
          proofPoints,
          publicSignals: pubSignals3,
        }),
      ).to.be.true;
      expect(await verifierHelper.verifyProofPointsStruct(await verifier3.getAddress(), proofPoints, pubSignals3)).to.be
        .true;
      expect(await verifierHelper.verifyProof(await verifier3.getAddress(), a, b, c, pubSignals3)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(
        await verifierHelper.verifyProofGroth16ProofStruct(await verifier2.getAddress(), {
          proofPoints,
          publicSignals: pubSignals2,
        }),
      ).to.be.false;
      expect(await verifierHelper.verifyProofPointsStruct(await verifier2.getAddress(), proofPoints, pubSignals2)).to.be
        .false;
      expect(await verifierHelper.verifyProof(await verifier2.getAddress(), a, b, c, pubSignals2)).to.be.false;
    });

    it("should get exception if failed to call verifyProof function", async () => {
      const wrongPubSignals = [1, 1, 2, 3];

      await expect(
        verifierHelper.verifyProofGroth16ProofStruct(await verifier2.getAddress(), {
          proofPoints,
          publicSignals: wrongPubSignals,
        }),
      )
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
      await expect(verifierHelper.verifyProofPointsStruct(await verifier2.getAddress(), proofPoints, wrongPubSignals))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
      await expect(verifierHelper.verifyProof(await verifier3.getAddress(), a, b, c, wrongPubSignals))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
    });
  });

  describe("verifyProofSafe", () => {
    it("should correctly call verifyProof function with additional checks", async () => {
      expect(
        await verifierHelper.verifyProofGroth16ProofStructSafe(
          await verifier3.getAddress(),
          { proofPoints, publicSignals: pubSignals3 },
          3,
        ),
      ).to.be.true;
      expect(
        await verifierHelper.verifyProofPointsStructSafe(await verifier3.getAddress(), proofPoints, pubSignals3, 3),
      ).to.be.true;
      expect(await verifierHelper.verifyProofSafe(await verifier3.getAddress(), a, b, c, pubSignals3, 3)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(
        await verifierHelper.verifyProofGroth16ProofStructSafe(
          await verifier2.getAddress(),
          { proofPoints, publicSignals: pubSignals2 },
          2,
        ),
      ).to.be.false;
      expect(
        await verifierHelper.verifyProofPointsStructSafe(await verifier2.getAddress(), proofPoints, pubSignals2, 2),
      ).to.be.false;
      expect(await verifierHelper.verifyProofSafe(await verifier2.getAddress(), a, b, c, pubSignals2, 2)).to.be.false;
    });

    it("should get an exception if it passes invalid public signals arr", async () => {
      await expect(
        verifierHelper.verifyProofGroth16ProofStructSafe(
          await verifier2.getAddress(),
          { proofPoints, publicSignals: pubSignals2 },
          4,
        ),
      )
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals2.length, 4);
      await expect(
        verifierHelper.verifyProofPointsStructSafe(await verifier2.getAddress(), proofPoints, pubSignals2, 4),
      )
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals2.length, 4);
      await expect(verifierHelper.verifyProofSafe(await verifier3.getAddress(), a, b, c, pubSignals3, 4))
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals3.length, 4);
    });
  });
});
