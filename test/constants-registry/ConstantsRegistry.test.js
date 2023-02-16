const { accounts } = require("../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const ConstantsRegistry = artifacts.require("ConstantsRegistryMock");

ConstantsRegistry.numberFormat = "BigNumber";

describe.only("ConstantsRegistry", () => {
  let OWNER;
  let SECOND;

  let constantsRegistry;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    constantsRegistry = await ConstantsRegistry.new();

    await constantsRegistry.__OwnableConstantsRegistry_init();
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(constantsRegistry.mockInit(), "Initializable: contract is not initializing");
      await truffleAssert.reverts(
        constantsRegistry.__OwnableConstantsRegistry_init(),
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("dev", () => {
    it("dev", async () => {
      await constantsRegistry.setUint256Constant(["A", "B", "C", "D", "E"], 1337);

      console.log((await constantsRegistry.getUint256Constant(["A", "B", "C", "D", "E"])).toNumber());
    });
  });
});
