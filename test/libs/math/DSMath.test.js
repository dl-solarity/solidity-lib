const { assert } = require("chai");
const { toBN } = require("../../../scripts/helpers/utils");

const DSMath = artifacts.require("DSMathMock");

DSMath.numberFormat = "BigNumber";

const BASE = toBN(10).pow(toBN(9));

const assertBNequal = (actual, expected) => {
  assert.isTrue(toBN(actual).eq(toBN(expected)), `${actual} should equal ${expected}`);
};

describe("DSMath", () => {
  let dsMath;

  before("setup", async () => {
    dsMath = await DSMath.new();
  });

  describe("rpow", () => {
    it("should calculate power for decimals", async () => {
      const cases = [
        [2, 3, 1, 8], // 2.0^3 = 8.0
        [150, 2, 10, 2250], // 15.0^2 = 225.0
        [BASE.multipliedBy(2), 3, BASE, BASE.multipliedBy(8)], // 2.000_000_000^3 = 8.000_000_000
        [BASE.multipliedBy(2.5), 3, BASE, BASE.multipliedBy(15.625)],
        [BASE.multipliedBy(123456), 3, BASE, BASE.multipliedBy(1881640295202816)],
        [BASE.multipliedBy(0.5), 2, BASE, BASE.multipliedBy(0.25)],
      ];

      for (const [base, exponent, mod, expected] of cases) {
        const result = await dsMath.rpow(base, exponent, mod);
        assertBNequal(result, expected);
      }
    });
  });
});
