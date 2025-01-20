import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { U512Mock } from "@ethers-v6";

describe("U512", () => {
  const reverter = new Reverter();

  let u512: U512Mock;

  function randomU512(): string {
    return "0x" + ethers.toBigInt(ethers.randomBytes(64)).toString(16).padStart(128, "0");
  }

  function toBytes(value: bigint): string {
    return "0x" + value.toString(16).padStart(128, "0");
  }

  function modadd(a: string, b: string, m: string): string {
    return toBytes((ethers.toBigInt(a) + ethers.toBigInt(b)) % ethers.toBigInt(m));
  }

  function modmul(a: string, b: string, m: string): string {
    return toBytes((ethers.toBigInt(a) * ethers.toBigInt(b)) % ethers.toBigInt(m));
  }

  function modexp(a: string, b: string, m: string): string {
    return toBytes(ethers.toBigInt(a) ** ethers.toBigInt(b) % ethers.toBigInt(m));
  }

  function modsub(a: string, b: string, m: string): string {
    const aBn = ethers.toBigInt(a);
    const bBn = ethers.toBigInt(b);
    const mBn = ethers.toBigInt(m);

    return toBytes((((aBn - bBn) % mBn) + mBn) % mBn);
  }

  before(async () => {
    const U512Mock = await ethers.getContractFactory("U512Mock");

    u512 = await U512Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  it("modadd test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();

      expect(await u512.modadd(a, b, m)).to.equal(modadd(a, b, m));
    }
  });

  it("modmul test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();

      expect(await u512.modmul(a, b, m)).to.equal(modmul(a, b, m));
    }
  });

  it("modsub test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();

      expect(await u512.modsub(a, b, m)).to.equal(modsub(a, b, m));
    }
  });

  it("modexp test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = toBytes(100n);
      const m = randomU512();

      expect(await u512.modexp(a, b, m)).to.equal(modexp(a, b, m));
    }
  });

  it("moddiv test", async () => {
    const a = toBytes(779149564533142355434093157610126726613246737199n);
    const b = toBytes(29118654464229156312755475164902924590603964377702716942232927993582928167089n);
    const m = toBytes(76884956397045344220809746629001649092737531784414529538755519063063536359079n);

    const expected = toBytes(30823410400962253491978005949535646087432096635784775122170630924100507445065n);

    expect(await u512.moddiv(a, b, m)).to.equal(expected);
  });
});
