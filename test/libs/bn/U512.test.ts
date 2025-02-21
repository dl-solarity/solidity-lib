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
    const aBigInt = ethers.toBigInt(a);
    const bBigInt = ethers.toBigInt(b);
    const mBigInt = ethers.toBigInt(m);

    return toBytes((((aBigInt - bBigInt) % mBigInt) + mBigInt) % mBigInt);
  }

  function moddiv(a: string, b: string, m: string) {
    const aBigInt = ethers.toBigInt(a);
    const mBigInt = ethers.toBigInt(m);

    const bInv = modinv(b, m);

    const result = (aBigInt * ethers.toBigInt(bInv)) % mBigInt;

    return toBytes(result);
  }

  function and(a: string, b: string): string {
    return toBytes(ethers.toBigInt(a) & ethers.toBigInt(b));
  }

  function or(a: string, b: string): string {
    return toBytes(ethers.toBigInt(a) | ethers.toBigInt(b));
  }

  function xor(a: string, b: string): string {
    return toBytes(ethers.toBigInt(a) ^ ethers.toBigInt(b));
  }

  function not(a: string): string {
    // ~a = -a - 1
    const maxUint512 = (BigInt(1) << BigInt(512)) - 1n;

    return sub(toBytes(maxUint512), a);
  }

  function shl(a: string, b: number): string {
    const maxUint512 = BigInt(1) << BigInt(512);

    return toBytes((ethers.toBigInt(a) << BigInt(b)) % maxUint512);
  }

  function shr(a: string, b: number): string {
    return toBytes(ethers.toBigInt(a) >> BigInt(b));
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

  it("assign test", async () => {
    const [pointerOriginal, pointerAssign, valueOriginal, valueAssign] = await u512.assign(prime);

    expect(pointerOriginal).to.not.eq(pointerAssign);
    expect(valueOriginal).to.be.equal(valueAssign);
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

  it("eqU256 test", async () => {
    expect(await u512.eqU256(toBytes(1020n), 1002n)).to.be.false;
    expect(await u512.eqU256(toBytes(200n), 200n)).to.be.true;
    expect(await u512.eqU256("0x00", 0)).to.be.true;
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
      expect(await u512.modAlloc(a, m)).to.be.equal(mod(a, m));
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
      expect(await u512.modinvAlloc(a, m)).to.be.equal(modinv(a, m));
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
      expect(await u512.modaddAlloc(a, b, m)).to.equal(modadd(a, b, m));
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
      expect(await u512.redaddAlloc(a, b, m)).to.equal(modadd(a, b, m));
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
      expect(await u512.modmulAlloc(a, b, m)).to.equal(modmul(a, b, m));
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
      expect(await u512.modsubAlloc(a, b, m)).to.equal(modsub(a, b, m));
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
      expect(await u512.redsubAlloc(a, b, m)).to.equal(modsub(a, b, m));
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
      expect(await u512.modexpAlloc(a, b, m)).to.equal(modexp(a, b, m));
      expect(await u512.modexpAssign(a, b, m)).to.equal(modexp(a, b, m));
      expect(await u512.modexpAssignTo(a, b, m, to)).to.equal(modexp(a, b, m));
    }
  });

  it("modexpU256 test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = 100n;
      const m = randomU512();
      const to = randomU512();

      expect(await u512.modexpU256(a, b, m)).to.equal(modexp(a, toBytes(b), m));
      expect(await u512.modexpU256Alloc(a, b, m)).to.equal(modexp(a, toBytes(b), m));
      expect(await u512.modexpU256Assign(a, b, m)).to.equal(modexp(a, toBytes(b), m));
      expect(await u512.modexpU256AssignTo(a, b, m, to)).to.equal(modexp(a, toBytes(b), m));
    }
  });

  it("moddiv test", async () => {
    const m = toBytes(prime);

    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.moddiv(a, b, m)).to.be.equal(moddiv(a, b, m));
      expect(await u512.moddivAlloc(a, b, m)).to.be.equal(moddiv(a, b, m));
      expect(await u512.moddivAssign(a, b, m)).to.be.equal(moddiv(a, b, m));
      expect(await u512.moddivAssignTo(a, b, m, to)).to.be.equal(moddiv(a, b, m));
    }
  });

  it("and test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.and(a, b)).to.be.equal(and(a, b));
      expect(await u512.andAssign(a, b)).to.be.equal(and(a, b));
      expect(await u512.andAssignTo(a, b, to)).to.be.equal(and(a, b));
    }
  });

  it("or test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.or(a, b)).to.be.equal(or(a, b));
      expect(await u512.orAssign(a, b)).to.be.equal(or(a, b));
      expect(await u512.orAssignTo(a, b, to)).to.be.equal(or(a, b));
    }
  });

  it("xor test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const b = randomU512();
      const to = randomU512();

      expect(await u512.xor(a, b)).to.be.equal(xor(a, b));
      expect(await u512.xorAssign(a, b)).to.be.equal(xor(a, b));
      expect(await u512.xorAssignTo(a, b, to)).to.be.equal(xor(a, b));
    }
  });

  it("not test", async () => {
    for (let i = 0; i < 100; ++i) {
      const a = randomU512();
      const to = randomU512();

      expect(await u512.not(a)).to.be.equal(not(a));
      expect(await u512.notAssign(a)).to.be.equal(not(a));
      expect(await u512.notAssignTo(a, to)).to.be.equal(not(a));
    }
  });

  it("shl test", async () => {
    for (let b = 0; b < 256; ++b) {
      const a = randomU512();
      const to = randomU512();

      expect(await u512.shl(a, b)).to.be.equal(shl(a, b));
      expect(await u512.shlAssign(a, b)).to.be.equal(shl(a, b));
      expect(await u512.shlAssignTo(a, b, to)).to.be.equal(shl(a, b));
    }
  });

  it("shr test", async () => {
    for (let b = 0; b < 256; ++b) {
      const a = randomU512();
      const to = randomU512();

      expect(await u512.shr(a, b)).to.be.equal(shr(a, b));
      expect(await u512.shrAssign(a, b)).to.be.equal(shr(a, b));
      expect(await u512.shrAssignTo(a, b, to)).to.be.equal(shr(a, b));
    }
  });
});
