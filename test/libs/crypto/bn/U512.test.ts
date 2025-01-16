import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { U512Mock } from "@ethers-v6";

describe("U512", () => {
  const reverter = new Reverter();

  let u512: U512Mock;

  function randomU512(): string {
    return "0x" + ethers.toBigInt(ethers.randomBytes(64)).toString(16);
  }

  function modadd(a: string, b: string, m: string): string {
    return "0x" + ((ethers.toBigInt(a) + ethers.toBigInt(b)) % ethers.toBigInt(m)).toString(16).padStart(128, "0");
  }

  before(async () => {
    const U512Mock = await ethers.getContractFactory("U512Mock");

    u512 = await U512Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  it.only("modadd test", async () => {
    const a = randomU512();
    const b = randomU512();
    const m = randomU512();

    expect(await u512.modadd(a, b, m)).to.equal(modadd(a, b, m));
  });
});
