import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import type { EC256Mock } from "@ethers-v6";

import { secp256k1 } from "@noble/curves/secp256k1";

const { ethers, networkHelpers } = await hre.network.connect();

describe("EC256", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let ec256: EC256Mock;

  before("setup", async () => {
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

  describe("negatePoint", () => {
    it("should negate point correctly", async () => {
      const p = secp256k1.Point.BASE.multiply(123n);

      expect(await ec256.negatePoint(p.toAffine())).to.be.deep.equal([p.x, secp256k1.Point.CURVE().p - p.y]);
      expect(await ec256.negatePoint({ x: 15, y: 0 })).to.be.deep.equal([15, 0]);
    });
  });

  describe("subPoint", () => {
    it("should subtract point correctly", async () => {
      const p1 = secp256k1.Point.BASE.multiply(123n);
      const p2 = secp256k1.Point.BASE.multiply(122n);
      const p3 = p1.add(p2);

      expect(await ec256.subPoint(p1, secp256k1.Point.BASE.toAffine())).to.be.deep.equal([p2.x, p2.y]);
      expect(await ec256.subPoint(p3.toAffine(), p2.toAffine())).to.be.deep.equal([p1.x, p1.y]);
    });
  });
});
