import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { ECDSA512Mock } from "@ethers-v6";

describe.skip("ECDSA512", () => {
  const reverter = new Reverter();

  let ecdsa512: ECDSA512Mock;

  before(async () => {
    const ECDSA512Mock = await ethers.getContractFactory("ECDSA512Mock");

    ecdsa512 = await ECDSA512Mock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("brainpoolP512r1", () => {
    const signature =
      "0x0bd2593447cc6c02caf99d60418dd42e9a194c910e6755ed0c7059acac656b04ccfe1e8348462ee43066823aee2fed7ca012e9890dfb69866d7ae88b6506f9c744b42304e693796618d090dbcb2a2551c3cb78534611e61fd9d1a5c0938b5b8ec6ed53d2d28999eabbd8e7792d167fcf582492403a6a0f7cc94c73a28fb76b71";
    const pubKey =
      "0x67cea1bedf84cbdcba69a05bb2ce3a2d1c9d911d236c480929a16ad697b45a6ca127079fe8d7868671e28ef33bdf9319e2e51c84b190ac5c91b51baf0a980ba500a7e79006194b5378f65cbe625ef2c47c64e56040d873b995b5b1ebaa4a6ce971da164391ff619af3bcfc71c5e1ad27ee0e859c2943e2de8ef7c43d3c976e9b";
    const message =
      "0x43f800fbeaf9238c58af795bcdad04bc49cd850c394d3382953356b023210281757b30e19218a37cbd612086fbc158caa8b4e1acb2ec00837e5d941f342fb3cc";

    it("should verify the signature", async () => {
      expect(await ecdsa512.verifyBrainpoolP512r1WithoutHashing(message, signature, pubKey)).to.be.true;
    });
  });
});
