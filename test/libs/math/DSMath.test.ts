import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { DSMathMock } from "@ethers-v6";

describe("DSMath", () => {
  const reverter = new Reverter();

  let dsMath: DSMathMock;

  before("setup", async () => {
    const DSMathMock = await ethers.getContractFactory("DSMathMock");
    dsMath = await DSMathMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("rpow()", () => {
    it("should calculate power for decimals", async () => {
      const BASE = 10n ** 9n;

      const cases = [
        [2, 3, 1, 8], // 2.0 ^ 3 = 8.0
        [150, 2, 10, 2250], // 15.0 ^ 2 = 225.0
        [BASE * 2n, 3, BASE, BASE * 8n], // 2.000_000_000 ^ 3 = 8.000_000_000
        [(BASE * 25n) / 10n, 3, BASE, (BASE * 15625n) / 1000n],
        [BASE * 123456n, 3, BASE, BASE * 1881640295202816n],
        [(BASE * 5n) / 10n, 2, BASE, (BASE * 25n) / 100n],
      ];

      for (const [base, exponent, mod, expected] of cases) {
        const result = await dsMath.rpow(base, exponent, mod);

        expect(result).to.equal(expected);
      }
    });
  });
});
