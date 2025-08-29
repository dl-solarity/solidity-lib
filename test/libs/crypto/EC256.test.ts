import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { EC256Mock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("EC256", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let ec256: EC256Mock;

  before(async () => {
    const EC256Mock = await ethers.getContractFactory("EC256Mock");

    ec256 = await EC256Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("toAffine", () => {
    it("should return zero affine", async () => {
      expect(await ec256.affineInfinity()).to.deep.equal([0, 0]);
    });
  });

  describe("basepoint", () => {
    it("should return correct basepoint", async () => {
      const secp256k1 = await ec256.secp256k1CurveParams();

      expect(await ec256.basepoint()).to.deep.equal([secp256k1.gx, secp256k1.gy]);
    });
  });
});
