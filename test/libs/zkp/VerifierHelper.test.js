const { assert } = require("chai");
const truffleAssert = require("truffle-assertions");

const VerifierHelperMock = artifacts.require("VerifierHelperMock");
const Verifier2Mock = artifacts.require("Verifier2Mock");
const Verifier3Mock = artifacts.require("Verifier3Mock");

VerifierHelperMock.numberFormat = "BigNumber";

describe("VerifierHelper", () => {
  let verifierHelper;
  let verifier2;
  let verifier3;

  const a = [10, 20];
  const b = [
    [1, 2],
    [3, 4],
  ];
  const c = [30, 40];
  const pubSignals2 = [2, 4];
  const pubSignals3 = [3, 6, 9];

  beforeEach("setup", async () => {
    verifierHelper = await VerifierHelperMock.new();

    verifier2 = await Verifier2Mock.new(true, pubSignals2);
    verifier3 = await Verifier3Mock.new(true, pubSignals3);
  });

  describe("verifyProof", () => {
    it("should correctly call verifyProof function", async () => {
      assert.isTrue(await verifierHelper.verifyProof(verifier3.address, pubSignals3, [a, b, c]));
      assert.isTrue(await verifierHelper.verifyProof(verifier3.address, pubSignals3, a, b, c));

      await verifier2.setVerifyResult(false);

      assert.isFalse(await verifierHelper.verifyProof(verifier2.address, pubSignals2, [a, b, c]));
      assert.isFalse(await verifierHelper.verifyProof(verifier2.address, pubSignals2, a, b, c));
    });

    it("should get exception if failed to call verifyProof function", async () => {
      const reason = "VerifierHelper: failed to call verifyProof function";

      const wrongPubSignals = [1, 1, 2, 3];

      await truffleAssert.reverts(verifierHelper.verifyProof(verifier2.address, wrongPubSignals, [a, b, c]), reason);
      await truffleAssert.reverts(verifierHelper.verifyProof(verifier3.address, wrongPubSignals, a, b, c), reason);
    });
  });

  describe("verifyProofSafe", () => {
    it("should correctly call verifyProof function with additional checks", async () => {
      assert.isTrue(await verifierHelper.verifyProofSafe(verifier3.address, pubSignals3, [a, b, c], 3));
      assert.isTrue(await verifierHelper.verifyProofSafe(verifier3.address, pubSignals3, a, b, c, 3));

      await verifier2.setVerifyResult(false);

      assert.isFalse(await verifierHelper.verifyProofSafe(verifier2.address, pubSignals2, [a, b, c], 2));
      assert.isFalse(await verifierHelper.verifyProofSafe(verifier2.address, pubSignals2, a, b, c, 2));
    });

    it("should get an exception if it passes invalid public signals arr", async () => {
      const reason = "VerifierHelper: invalid public signals count";

      await truffleAssert.reverts(verifierHelper.verifyProofSafe(verifier2.address, pubSignals2, [a, b, c], 4), reason);
      await truffleAssert.reverts(verifierHelper.verifyProofSafe(verifier3.address, pubSignals3, a, b, c, 4), reason);
    });
  });
});
