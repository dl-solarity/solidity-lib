import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { getModifiedSigOrPubKey } from "@/test/helpers/signature-helper";

import { ECDSA384Mock } from "@ethers-v6";

describe("ECDSA384", () => {
  const reverter = new Reverter();

  let ecdsa384: ECDSA384Mock;

  before(async () => {
    const ECDSA384Mock = await ethers.getContractFactory("ECDSA384Mock");

    ecdsa384 = await ECDSA384Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("SECP384r1", () => {
    const signature =
      "0x3044b552135e5eb46368e739b3138f9f1f2eb37a0518f564d2767d02ac67a9f41fb71bad06a99f54ee2e43ead2916f630e07a31eb5214798e5ecb032e49585f5d3d52b6f74d8bd71fbfd606a4466ae7a33723520475d1367c1a35e30a0e80a96";
    const pubKey =
      "0x56931fd7d42942eec92298d7291371cdbac29c60230c9f635d010939ab7f8f5d977ccfe90bd7528cafa53afad6225bf61e2af4d20831aed1e6b578ccb00e1534182f6d1ee6bf524fbd62bd056d0d538c24eb7f2a436e336e139f00a072b0ba1a";
    const message =
      "0x308203cfa0030201020204492f01a0300a06082a8648ce3d0403023041310b3009060355040613024742310e300c060355040a1305554b4b50413122302006035504031319436f756e747279205369676e696e6720417574686f72697479301e170d3232303830313030303030305a170d3333313230313030303030305a305c310b3009060355040613024742311b3019060355040a1312484d2050617373706f7274204f6666696365310f300d060355040b13064c6f6e646f6e311f301d06035504031316446f63756d656e74205369676e696e67204b657920363082014b3082010306072a8648ce3d02013081f7020101302c06072a8648ce3d0101022100ffffffff00000001000000000000000000000000ffffffffffffffffffffffff305b0420ffffffff00000001000000000000000000000000fffffffffffffffffffffffc04205ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b031500c49d360886e704936a6678e1139d26b7819f7e900441046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2964fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5022100ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc63255102010103420004369b6087115805a184e0a04e522acc1c58959aa0c9b19d80c8dd293fdd504ec0675381123b71874d105693f18105022fe4eb9ac7c2dfbcdcc58cbd7351d263d4a38201a4308201a030420603551d11043b30398125646f63756d656e742e746563686e6f6c6f677940686f6d656f66666963652e676f762e756ba410300e310c300a06035504071303474252302b0603551d1004243022800f32303232303830313030303030305a810f32303232313130343030303030305a300e0603551d0f0101ff04040302078030630603551d12045c305aa410300e310c300a06035504071303474252811f646f63756d656e742e746563686e6f6c6f677940686d706f2e676f762e756b8125646f63756d656e742e746563686e6f6c6f677940686f6d656f66666963652e676f762e756b3019060767810801010602040e300c020100310713015013025054305d0603551d1f045630543052a050a04e862068747470733a2f2f686d706f2e676f762e756b2f637363612f4742522e63726c862a68747470733a2f2f706b64646f776e6c6f6164312e6963616f2e696e742f43524c732f4742522e63726c301f0603551d23041830168014499e4730278520c57cfc118024e14c1562a249d6301d0603551d0e0416041439b5abb7415fb8629b55c137d12a01c35fb49486";

    describe("verify", () => {
      it("should verify signature", async () => {
        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.true;
      });

      it("should not verify invalid signature", async () => {
        const message = "0x0123456789";

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not verify if U384.eqInteger(inputs_.r, 0) is true", async () => {
        const sigWithZeroR = getModifiedSigOrPubKey(true, "0");

        expect(await ecdsa384.verifySECP384r1(message, sigWithZeroR, pubKey)).to.be.false;
      });

      it("should not verify if U384.eqInteger(inputs_.s, 0) is true", async () => {
        const sigWithZeroS = getModifiedSigOrPubKey(false, "0");

        expect(await ecdsa384.verifySECP384r1(message, sigWithZeroS, pubKey)).to.be.false;
      });

      it("should not verify if U384.cmp(inputs_.r, params_.n) >= 0", async () => {
        const n = "ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973";

        const signature = getModifiedSigOrPubKey(true, n);

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not verify if U384.cmp(inputs_.s, params_.lowSmax) > 0", async () => {
        const lowSmaxPlusOne =
          "7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb5666294ba";

        const signature = getModifiedSigOrPubKey(false, lowSmaxPlusOne);

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should revert if curve parameters have an invalid length", async () => {
        await expect(
          ecdsa384.verifySECP384r1CustomCurveParameters(message, signature, pubKey, "0x", "0x"),
        ).to.be.revertedWith("U384: not 384");
      });

      it("should revert if signature or public key has an invalid length", async () => {
        const wrongSig =
          "0x3066023100a2fcd465ab5b507fc55941c1c6cd8286de04b83c94c6be25b5bdf58e27d86c3759d5f94ffcbd009618b6371bc51994f0023100d708d5045caa4a61cad42622c14bfb3343a5a9dc8fdbd19ce46b9e24c2aff84ba5114bb543fc4b0099f369079302b721";

        await expect(ecdsa384.verifySECP384r1(message, wrongSig, pubKey)).to.be.revertedWith("U384: not 768");

        const wrongPubKey =
          "0x3076301006072a8648ce3d020106052b81040022036200041d77728fada41a8a7a23fe922e4e2dc8881a94b72a0612077ad80eeef13ff3bbea92aeef36a0f65885417aea104b86b76aedc226e260f7d0eeea8405b9269f354d929e5a98cab64fe192db94ed9335b7395e38e99b8bfaf32effa163a92889f9";

        await expect(ecdsa384.verifySECP384r1(message, signature, wrongPubKey)).to.be.revertedWith("U384: not 768");
      });

      it("should not revert when message is hashed using SHA-384", async () => {
        const hashed384Message =
          "0x576c1527e84521aac7ba48de1f22ac732e117c3cac1a51b5f44c0b2af3f281c2cccc51707d7a1b12b9085c24f00fd251";

        expect(await ecdsa384.verifySECP384r1WithoutHashing(hashed384Message, signature, pubKey)).to.be.false;
      });
    });

    describe("_isOnCurve", () => {
      const p = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff";

      it("should not verify if U384.eqInteger(x, 0) is true", async () => {
        const pubKey = getModifiedSigOrPubKey(true, "0");

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not verify if U384.eqInteger(y, 0) is true", async () => {
        const pubKey = getModifiedSigOrPubKey(false, "0");

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not verify if U384.eq(x, p) is true", async () => {
        const pubKey = getModifiedSigOrPubKey(true, p);

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not verify if U384.eq(y, p) is true", async () => {
        const pubKey = getModifiedSigOrPubKey(false, p);

        expect(await ecdsa384.verifySECP384r1(message, signature, pubKey)).to.be.false;
      });

      it("should not revert if the a or b curve parameters are zero", async () => {
        const zeroParameter =
          "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        expect(
          await ecdsa384.verifySECP384r1CustomCurveParameters(message, signature, pubKey, zeroParameter, zeroParameter),
        ).to.be.false;
      });
    });
  });
});