import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";

import { PlonkVerifierHelperMock, PlonkVerifier2Mock, PlonkVerifier3Mock } from "@ethers-v6";

describe("PlonkVerifierHelper", () => {
  const reverter = new Reverter();

  let verifierHelper: PlonkVerifierHelperMock;
  let verifier2: PlonkVerifier2Mock;
  let verifier3: PlonkVerifier3Mock;

  const proofData = new Array<number>(24).fill(10);
  const proofPoints = { proofData };

  const pubSignals2 = [2, 4];
  const pubSignals3 = [3, 6, 9];

  before("setup", async () => {
    const PlonkVerifierHelperMock = await ethers.getContractFactory("PlonkVerifierHelperMock");
    const PlonkVerifier2Mock = await ethers.getContractFactory("PlonkVerifier2Mock");
    const PlonkVerifier3Mock = await ethers.getContractFactory("PlonkVerifier3Mock");

    verifierHelper = await PlonkVerifierHelperMock.deploy();

    verifier2 = await PlonkVerifier2Mock.deploy(true, pubSignals2);
    verifier3 = await PlonkVerifier3Mock.deploy(true, pubSignals3);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("verifyProof", () => {
    it("should correctly call verifyProof function", async () => {
      expect(
        await verifierHelper.verifyProofPlonkProofStruct(await verifier3.getAddress(), {
          proofPoints,
          publicSignals: pubSignals3,
        }),
      ).to.be.true;
      expect(await verifierHelper.verifyProofPointsStruct(await verifier3.getAddress(), proofPoints, pubSignals3)).to.be
        .true;
      expect(await verifierHelper.verifyProof(await verifier3.getAddress(), proofData, pubSignals3)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(
        await verifierHelper.verifyProofPlonkProofStruct(await verifier2.getAddress(), {
          proofPoints,
          publicSignals: pubSignals2,
        }),
      ).to.be.false;
      expect(await verifierHelper.verifyProofPointsStruct(await verifier2.getAddress(), proofPoints, pubSignals2)).to.be
        .false;
      expect(await verifierHelper.verifyProof(await verifier2.getAddress(), proofData, pubSignals2)).to.be.false;
    });

    it("should get exception if failed to call verifyProof function", async () => {
      const wrongPubSignals = [1, 1, 2, 3];

      await expect(
        verifierHelper.verifyProofPlonkProofStruct(await verifier2.getAddress(), {
          proofPoints,
          publicSignals: wrongPubSignals,
        }),
      )
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
      await expect(verifierHelper.verifyProofPointsStruct(await verifier2.getAddress(), proofPoints, wrongPubSignals))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
      await expect(verifierHelper.verifyProof(await verifier3.getAddress(), proofData, wrongPubSignals))
        .to.be.revertedWithCustomError(verifierHelper, "FailedToCallVerifyProof")
        .withArgs();
    });
  });

  describe("verifyProofSafe", () => {
    it("should correctly call verifyProof function with additional checks", async () => {
      expect(
        await verifierHelper.verifyProofPlonkProofStructSafe(
          await verifier3.getAddress(),
          { proofPoints, publicSignals: pubSignals3 },
          3,
        ),
      ).to.be.true;
      expect(
        await verifierHelper.verifyProofPointsStructSafe(await verifier3.getAddress(), proofPoints, pubSignals3, 3),
      ).to.be.true;
      expect(await verifierHelper.verifyProofSafe(await verifier3.getAddress(), proofData, pubSignals3, 3)).to.be.true;

      await verifier2.setVerifyResult(false);

      expect(
        await verifierHelper.verifyProofPlonkProofStructSafe(
          await verifier2.getAddress(),
          { proofPoints, publicSignals: pubSignals2 },
          2,
        ),
      ).to.be.false;
      expect(
        await verifierHelper.verifyProofPointsStructSafe(await verifier2.getAddress(), proofPoints, pubSignals2, 2),
      ).to.be.false;
      expect(await verifierHelper.verifyProofSafe(await verifier2.getAddress(), proofData, pubSignals2, 2)).to.be.false;
    });

    it("should get an exception if it passes invalid public signals arr", async () => {
      await expect(
        verifierHelper.verifyProofPlonkProofStructSafe(
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
      await expect(verifierHelper.verifyProofSafe(await verifier3.getAddress(), proofData, pubSignals3, 4))
        .to.be.revertedWithCustomError(verifierHelper, "InvalidPublicSignalsCount")
        .withArgs(pubSignals3.length, 4);
    });
  });
});
