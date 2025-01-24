import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { U512Mock } from "@ethers-v6";

describe("U512", () => {
  const reverter = new Reverter();

  const prime = 76884956397045344220809746629001649092737531784414529538755519063063536359079n;

  let u512: U512Mock;

  function randomU512(): string {
    return "0x" + ethers.toBigInt(ethers.randomBytes(64)).toString(16).padStart(128, "0");
  }

  function toBytes(value: bigint): string {
    return "0x" + value.toString(16).padStart(128, "0");
  }

  function mod(a: string, m: string): string {
    return toBytes(ethers.toBigInt(a) % ethers.toBigInt(m));
  }

  function add(a: string, b: string): string {
    const maxUint512 = BigInt(1) << BigInt(512);

    const aBigInt = ethers.toBigInt(a);
    const bBigInt = ethers.toBigInt(b);

    const result = (aBigInt + bBigInt) % maxUint512;

    return toBytes(result);
  }

  function sub(a: string, b: string): string {
    const maxUint512 = BigInt(1) << BigInt(512);

    const aBigInt = ethers.toBigInt(a);
    const bBigInt = ethers.toBigInt(b);

    let result = (aBigInt - bBigInt) % maxUint512;

    if (result < 0) {
      result += maxUint512;
    }

    return toBytes(result);
  }

  function mul(a: string, b: string): string {
    const maxUint512 = BigInt(1) << BigInt(512);

    const aBigInt = ethers.toBigInt(a);
    const bBigInt = ethers.toBigInt(b);

    const result = (aBigInt * bBigInt) % maxUint512;

    return toBytes(result);
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

  function modinv(a: string, m: string): string {
    const aBigInt = ethers.toBigInt(a);
    const mBigInt = ethers.toBigInt(m);

    if (aBigInt <= 0n || mBigInt <= 0n) {
      throw new Error("Inputs must be positive integers.");
    }

    let [t, newT] = [0n, 1n];
    let [r, newR] = [mBigInt, aBigInt];

    while (newR !== 0n) {
      const quotient = r / newR;
      [t, newT] = [newT, t - quotient * newT];
      [r, newR] = [newR, r - quotient * newR];
    }

    if (r > 1n) {
      throw new Error("No modular inverse exists.");
    }

    if (t < 0n) {
      t += mBigInt;
    }

    return toBytes(t);
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

  it("copy test", async () => {
    const [pointerOriginal, pointerCopy, valueOriginal, valueCopy] = await u512.copy(prime);

    expect(pointerOriginal).to.be.lessThan(pointerCopy);
    expect(valueOriginal).to.be.equal(valueCopy);
  });

  it("isNull test", async () => {
    expect(await u512.isNull(0)).to.be.true;
    expect(await u512.isNull(64)).to.be.false;
  });

  it("eq test", async () => {
    expect(await u512.eq(toBytes(1020n), toBytes(1002n))).to.be.false;
    expect(await u512.eq(toBytes(200n), toBytes(200n))).to.be.true;
    expect(await u512.eq("0x00", "0x00")).to.be.true;
  });

  it("eqUint256 test", async () => {
    expect(await u512.eqUint256(toBytes(1020n), 1002n)).to.be.false;
    expect(await u512.eqUint256(toBytes(200n), 200n)).to.be.true;
    expect(await u512.eqUint256("0x00", 0)).to.be.true;
  });

  it("cmp test", async () => {
    expect(await u512.cmp(toBytes(705493n), toBytes(705492n))).to.be.equal(1);
    expect(await u512.cmp(toBytes(1n), "0x00")).to.be.equal(1);
    expect(await u512.cmp(toBytes(775n), toBytes(775n))).to.be.equal(0);
    expect(await u512.cmp("0x00", "0x00")).to.be.equal(0);
    expect(await u512.cmp(toBytes(380n), toBytes(400n))).to.be.equal(-1);
    expect(await u512.cmp("0x00", toBytes(12n))).to.be.equal(-1);
  });

  it("mod test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const m = randomU512();
      const to = randomU512();

      expect(await u512.mod(a, m)).to.be.equal(mod(a, m));
      expect(await u512.modAssign(a, m)).to.be.equal(mod(a, m));
      expect(await u512.modAssignTo(a, m, to)).to.be.equal(mod(a, m));
    }
  });

  it("modinv test", async () => {
    const m = toBytes(prime);

    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const to = randomU512();

      expect(await u512.modinv(a, m)).to.be.equal(modinv(a, m));
      expect(await u512.modinvAssign(a, m)).to.be.equal(modinv(a, m));
      expect(await u512.modinvAssignTo(a, m, to)).to.be.equal(modinv(a, m));
    }
  });

  it("add test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.add(a, b)).to.be.equal(add(a, b));
      expect(await u512.addAssign(a, b)).to.be.equal(add(a, b));
      expect(await u512.addAssignTo(a, b, to)).to.be.equal(add(a, b));
    }
  });

  it("sub test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.sub(a, b)).to.be.equal(sub(a, b));
      expect(await u512.subAssign(a, b)).to.be.equal(sub(a, b));
      expect(await u512.subAssignTo(a, b, to)).to.be.equal(sub(a, b));
    }
  });

  it("mul test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.mul(a, b)).to.be.equal(mul(a, b));
      expect(await u512.mulAssign(a, b)).to.be.equal(mul(a, b));
      expect(await u512.mulAssignTo(a, b, to)).to.be.equal(mul(a, b));
    }
  });

  it("modadd test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();
      const to = randomU512();

      expect(await u512.modadd(a, b, m)).to.equal(modadd(a, b, m));
      expect(await u512.modaddAssign(a, b, m)).to.equal(modadd(a, b, m));
      expect(await u512.modaddAssignTo(a, b, m, to)).to.equal(modadd(a, b, m));
    }
  });

  it("redadd test", async () => {
    for (let i = 0; i < 100; ++i) {
      const m = randomU512();

      const a = mod(randomU512(), m);
      const b = mod(randomU512(), m);

      const to = randomU512();

      expect(await u512.redadd(a, b, m)).to.equal(modadd(a, b, m));
      expect(await u512.redaddAssign(a, b, m)).to.equal(modadd(a, b, m));
      expect(await u512.redaddAssignTo(a, b, m, to)).to.equal(modadd(a, b, m));
    }
  });

  it("modmul test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();
      const to = randomU512();

      expect(await u512.modmul(a, b, m)).to.equal(modmul(a, b, m));
      expect(await u512.modmulAssign(a, b, m)).to.equal(modmul(a, b, m));
      expect(await u512.modmulAssignTo(a, b, m, to)).to.equal(modmul(a, b, m));
    }
  });

  it("modsub test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const m = randomU512();
      const to = randomU512();

      expect(await u512.modsub(a, b, m)).to.equal(modsub(a, b, m));
      expect(await u512.modsubAssign(a, b, m)).to.equal(modsub(a, b, m));
      expect(await u512.modsubAssignTo(a, b, m, to)).to.equal(modsub(a, b, m));
    }
  });

  it("redsub test", async () => {
    for (let i = 0; i < 100; ++i) {
      const m = randomU512();

      const a = mod(randomU512(), m);
      const b = mod(randomU512(), m);

      const to = randomU512();

      expect(await u512.redsub(a, b, m)).to.equal(modsub(a, b, m));
      expect(await u512.redsubAssign(a, b, m)).to.equal(modsub(a, b, m));
      expect(await u512.redsubAssignTo(a, b, m, to)).to.equal(modsub(a, b, m));
    }
  });

  it("modexp test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = toBytes(100n);
      const m = randomU512();
      const to = randomU512();

      expect(await u512.modexp(a, b, m)).to.equal(modexp(a, b, m));
      expect(await u512.modexpAssign(a, b, m)).to.equal(modexp(a, b, m));
      expect(await u512.modexpAssignTo(a, b, m, to)).to.equal(modexp(a, b, m));
    }
  });

  it("moddiv test", async () => {
    const m = toBytes(prime);

    const a = toBytes(779149564533142355434093157610126726613246737199n);
    const b = toBytes(29118654464229156312755475164902924590603964377702716942232927993582928167089n);

    const to = randomU512();

    const expected = toBytes(30823410400962253491978005949535646087432096635784775122170630924100507445065n);

    expect(await u512.moddiv(a, b, m)).to.equal(expected);
    expect(await u512.moddivAssign(a, b, m)).to.equal(expected);
    expect(await u512.moddivAssignTo(a, b, m, to)).to.equal(expected);
  });
});
