const { assert } = require("chai");
const { accounts } = require("../../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const RBACMock = artifacts.require("RBACGroupableMock");

RBACMock.numberFormat = "BigNumber";

describe("RBAC", () => {
  let OWNER;
  let SECOND;

  let rbac;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    rbac = await RBACMock.new();

    await rbac.__RBACMock_init();
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(rbac.mockInit(), "Initializable: contract is not initializing");
    });
  });
});
