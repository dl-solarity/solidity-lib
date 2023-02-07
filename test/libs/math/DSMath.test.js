const { assert } = require("chai");
const { toBN } = require("../../../scripts/utils/utils");

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

  describe("sqrt", () => {
    it("should compute square roots properly", async () => {
      const cases = [
        ["0", "0"],
        ["1", "1"],
        ["2", "1"],
        ["3", "1"],
        ["4", "2"],
        ["15", "3"],
        ["16", "4"],
        ["17", "4"],
        ["105", "10"],
        ["1787926567434221169891766654055630785600812306453167569", "1337133713371337133713371337"],
        [toBN(2).pow(254), toBN(2).pow(127)],
        [toBN(2).pow(256).minus(1), toBN(2).pow(128).minus(1)],
      ];

      for (const [square, root] of cases) {
        assertBNequal(await dsMath.sqrt(square), root);
      }
    });
  });
});
