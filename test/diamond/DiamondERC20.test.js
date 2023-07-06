const { assert } = require("chai");
const { accounts, wei } = require("../../scripts/utils/utils");
const { ZERO_ADDR, MAX_UINT256 } = require("../../scripts/utils/constants");
const truffleAssert = require("truffle-assertions");

const OwnableDiamond = artifacts.require("OwnableDiamond");
const DiamondERC20Mock = artifacts.require("DiamondERC20Mock");

OwnableDiamond.numberFormat = "BigNumber";
DiamondERC20Mock.numberFormat = "BigNumber";

function getSelectors(contract) {
  return Object.keys(contract.methods).map((el) => web3.eth.abi.encodeFunctionSignature(el));
}

describe("DiamondERC20 and InitializableStorage", () => {
  let OWNER;
  let SECOND;

  let erc20;
  let diamond;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    diamond = await OwnableDiamond.new();
    erc20 = await DiamondERC20Mock.new();

    const selectors = getSelectors(erc20);

    await diamond.addFacet(erc20.address, selectors);

    erc20 = await DiamondERC20Mock.at(diamond.address);

    erc20.__DiamondERC20Mock_init("Mock Token", "MT");
  });

  describe("access", () => {
    it("should initialize only once", async () => {
      await truffleAssert.reverts(
        erc20.__DiamondERC20Mock_init("Mock Token", "MT"),
        "Initializable: contract is already initialized"
      );
    });

    it("should initialize only by top level contract", async () => {
      await truffleAssert.reverts(
        erc20.__DiamondERC20Direct_init("Mock Token", "MT"),
        "Initializable: contract is not initializing"
      );
    });

    it("should disable implementation initialization", async () => {
      // Get the hash of the deployment transaction
      const contract = await DiamondERC20Mock.new();

      let txHash = contract.transactionHash;

      // Get the transaction result using truffleAssert
      let result = await truffleAssert.createTransactionResult(contract, txHash);

      await truffleAssert.eventEmitted(
        result,
        "Initialized",
        (ev) => {
          return ev.storageSlot === "0x53a65a27f49c2031551d6b34b2c7a820391e4944344eb7ed8a0fcb6ebb483840";
        },
        "Implementation should disable initialization."
      );

      await truffleAssert.reverts(contract.disableInitializers(), "Initializable: contract is initializing");
    });
  });

  describe("DiamondERC20 functions", () => {
    it("should transfer tokens", async () => {
      await erc20.mint(OWNER, wei("100"));

      await erc20.transfer(SECOND, wei("50"));

      assert.equal(await erc20.balanceOf(OWNER), wei("50"));
      assert.equal(await erc20.balanceOf(SECOND), wei("50"));
    });

    it("should not transfer tokens to/from zero address", async () => {
      await truffleAssert.reverts(erc20.transfer(SECOND, ZERO_ADDR, wei("100")), "ERC20: transfer to the zero address");
      await truffleAssert.reverts(
        erc20.transfer(ZERO_ADDR, SECOND, wei("100")),
        "ERC20: transfer from the zero address"
      );
    });

    it("should not transfer tokens if balance is insufficient", async () => {
      await truffleAssert.reverts(erc20.transfer(SECOND, wei("100")), "ERC20: transfer amount exceeds balance");
    });

    it("should mint tokens", async () => {
      await erc20.mint(OWNER, wei("100"));

      assert.equal(await erc20.balanceOf(OWNER), wei("100"));
    });

    it("should not mint tokens to zero address", async () => {
      await truffleAssert.reverts(erc20.mint(ZERO_ADDR, wei("100")), "ERC20: mint to the zero address");
    });

    it("should burn tokens", async () => {
      await erc20.mint(OWNER, wei("100"));

      await erc20.burn(OWNER, wei("50"));

      assert.equal(await erc20.balanceOf(OWNER), wei("50"));
    });

    it("should not burn tokens from zero address", async () => {
      await truffleAssert.reverts(erc20.burn(ZERO_ADDR, wei("100")), "ERC20: burn from the zero address");
    });

    it("should not burn tokens if balance is insufficient", async () => {
      await truffleAssert.reverts(erc20.burn(OWNER, wei("100")), "ERC20: burn amount exceeds balance");
    });

    it("should approve tokens", async () => {
      await erc20.approve(SECOND, wei("100"));

      assert.equal(await erc20.allowance(OWNER, SECOND), wei("100"));
    });

    it("should not approve tokens to/from zero address", async () => {
      await truffleAssert.reverts(erc20.approve(OWNER, ZERO_ADDR, wei("100")), "ERC20: approve to the zero address");
      await truffleAssert.reverts(erc20.approve(ZERO_ADDR, OWNER, wei("100")), "ERC20: approve from the zero address");
    });

    it("should transfer tokens from address", async () => {
      await erc20.mint(OWNER, wei("100"));

      await erc20.approve(SECOND, wei("100"));

      await erc20.transferFrom(OWNER, SECOND, wei("50"), { from: SECOND });

      assert.equal(await erc20.balanceOf(OWNER), wei("50"));
      assert.equal(await erc20.balanceOf(SECOND), wei("50"));
    });

    it("should not transfer tokens from address if balance is insufficient", async () => {
      await erc20.mint(OWNER, wei("100"));

      await erc20.approve(SECOND, wei("100"));

      await truffleAssert.reverts(
        erc20.transferFrom(OWNER, SECOND, wei("110"), { from: SECOND }),
        "ERC20: insufficient allowance"
      );
    });

    it("should not spend allowance if allowance is infinite type(uint256).max", async () => {
      await erc20.mint(OWNER, wei("100"));

      await erc20.approve(SECOND, MAX_UINT256);

      await erc20.transferFrom(OWNER, SECOND, wei("100"), { from: SECOND });

      assert.equal("0x" + (await erc20.allowance(OWNER, SECOND)).toString(16), MAX_UINT256);
    });

    it("should increase allowance", async () => {
      await erc20.increaseAllowance(SECOND, wei("100"));

      assert.equal(await erc20.allowance(OWNER, SECOND), wei("100"));
    });

    it("should decrease allowance", async () => {
      await erc20.approve(SECOND, wei("100"));

      await erc20.decreaseAllowance(SECOND, wei("50"));

      assert.equal(await erc20.allowance(OWNER, SECOND), wei("50"));
    });

    it("should not decrease allowance if allowance is insufficient", async () => {
      await erc20.approve(SECOND, wei("100"));

      await truffleAssert.reverts(erc20.decreaseAllowance(SECOND, wei("150")), "ERC20: decreased allowance below zero");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      assert.equal(await erc20.name(), "Mock Token");
      assert.equal(await erc20.symbol(), "MT");
      assert.equal(await erc20.decimals(), 18);

      await erc20.mint(OWNER, wei("100"));

      assert.equal(await erc20.balanceOf(OWNER), wei("100"));
      assert.equal(await erc20.totalSupply(), wei("100"));
    });
  });
});
