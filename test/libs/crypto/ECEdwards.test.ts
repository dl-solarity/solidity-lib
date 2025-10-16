import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";

import { ECEdwardsMock } from "@ethers-v6";

import { Base8, Point, addPoint, mulPointEscalar } from "@zk-kit/baby-jubjub";

const { ethers, networkHelpers } = await hre.network.connect();

describe("ECEdwards", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const p: Point<bigint> = [
    17777552123799933955779906779655732241715742912184938656739573121738514868268n,
    2626589144620713026669568689430873010625803728049924121243784502389097019475n,
  ];

  let babyJubJub: ECEdwardsMock;

  before("setup", async () => {
    const ECEdwardsMock = await ethers.getContractFactory("ECEdwardsMock");

    babyJubJub = await ECEdwardsMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("basepoint", () => {
    it("should return correct basepoint", async () => {
      expect(await babyJubJub.basepoint()).to.deep.equal(Base8);
      expect(await babyJubJub.pBasepoint()).to.deep.equal([Base8[0], Base8[1], 1]);

      const curveParams = await babyJubJub.babyJubJub();
      expect(await babyJubJub.equal([curveParams.gx, curveParams.gy], Base8)).to.be.true;
    });
  });

  describe("toScalar", () => {
    it("should return correct scalar", async () => {
      const curveParams = await babyJubJub.babyJubJub();

      const invalidScalar = curveParams.n + 5n;
      const validScalar = curveParams.n - 5n;

      expect(await babyJubJub.toScalar(invalidScalar)).to.be.equal(5n);

      expect(await babyJubJub.isValidScalar(invalidScalar)).to.be.false;
      expect(await babyJubJub.isValidScalar(validScalar)).to.be.true;
    });
  });

  describe("isOnCurve & infinity", () => {
    it("should check whether the point is on curve correctly", async () => {
      expect(await babyJubJub.isOnCurve(p)).to.be.true;
      expect(await babyJubJub.isOnCurve({ x: 0, y: 1 })).to.be.true;
      expect(await babyJubJub.isOnCurve({ x: p[0], y: p[1] + 2n })).to.be.false;
      expect(await babyJubJub.isOnCurve({ x: 0, y: 0 })).to.be.false;
    });

    it("should return infinity point correctly", async () => {
      const projectiveInfinity1 = [0, 1, 1];
      const projectiveInfinity2 = [0, 6, 6];

      const invalidProjectiveInfinity1 = [0, 2, 6];
      const invalidProjectiveInfinity2 = [1, 1, 1];

      expect(await babyJubJub.pInfinity()).to.be.deep.equal(projectiveInfinity1);
      expect(await babyJubJub.affineInfinity()).to.be.deep.equal([0, 1]);

      expect(await babyJubJub.isProjectiveInfinity(projectiveInfinity1)).to.be.true;
      expect(await babyJubJub.isProjectiveInfinity(projectiveInfinity2)).to.be.true;
      expect(await babyJubJub.isProjectiveInfinity(invalidProjectiveInfinity1)).to.be.false;
      expect(await babyJubJub.isProjectiveInfinity(invalidProjectiveInfinity2)).to.be.false;
    });
  });

  describe("addPoint", () => {
    it("should add two points correctly", async () => {
      expect(await babyJubJub.addPoint(p, Base8)).to.be.deep.equal(addPoint(p, Base8));
      expect(await babyJubJub.addPoint(Base8, p)).to.be.deep.equal(addPoint(p, Base8));
      expect(await babyJubJub.addPoint(p, p)).to.be.deep.equal(addPoint(p, p));
      expect(await babyJubJub.addPoint(Base8, Base8)).to.be.deep.equal(addPoint(Base8, Base8));
      expect(await babyJubJub.addPoint(p, { x: 0, y: 1 })).to.be.deep.equal(p);
      expect(await babyJubJub.addPoint({ x: 0, y: 1 }, Base8)).to.be.deep.equal(Base8);
    });
  });

  describe("double", () => {
    it("should double a point correctly", async () => {
      expect(await babyJubJub.doublePoint(p)).to.be.deep.equal(addPoint(p, p));
      expect(await babyJubJub.doublePoint(Base8)).to.be.deep.equal(addPoint(Base8, Base8));
      expect(await babyJubJub.doublePoint({ x: 0, y: 1 })).to.be.deep.equal([0, 1]);
    });
  });

  describe("multShamir", () => {
    it("should multiply a point by scalar correctly", async () => {
      expect(await babyJubJub.multShamir(p, 15)).to.be.deep.equal(mulPointEscalar(p, 15n));
      expect(await babyJubJub.multShamir(p, p[0])).to.be.deep.equal(mulPointEscalar(p, p[0]));
    });
  });

  describe("multShamir2", () => {
    it("should multiply two points by scalars and add them correctly", async () => {
      const p2 = addPoint(Base8, p);

      expect(await babyJubJub.multShamir2(Base8, p, p[0], p[1])).to.be.deep.equal(
        addPoint(mulPointEscalar(Base8, p[0]), mulPointEscalar(p, p[1])),
      );

      const p3 = await babyJubJub.multShamir2(p, p2, 10, 437828);
      const p4 = addPoint(mulPointEscalar(p, 10n), mulPointEscalar(p2, 437828n));
      const p5 = addPoint(mulPointEscalar(p, 437828n), mulPointEscalar(p2, 10n));

      expect(p3).to.be.deep.equal(p4);
      expect(await babyJubJub.equal(p4, p5)).to.be.false;
    });
  });
});
