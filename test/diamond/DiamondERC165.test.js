const { assert } = require("chai");
const { accounts, wei } = require("../../scripts/utils/utils");
const { ZERO_ADDR, MAX_UINT256 } = require("../../scripts/utils/constants");
const truffleAssert = require("truffle-assertions");

const OwnableDiamond = artifacts.require("OwnableDiamond");
const DiamondERC165 = artifacts.require("DiamondERC165");

OwnableDiamond.numberFormat = "BigNumber";
DiamondERC165.numberFormat = "BigNumber";

const FacetAction = {
  Add: 0,
  Replace: 1,
  Remove: 2,
};

function getSelectors(contract) {
  return Object.keys(contract.methods).map((el) => web3.eth.abi.encodeFunctionSignature(el));
}

describe("DiamondERC165", () => {
  let OWNER;
  let SECOND;

  let erc165;
  let diamond;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    diamond = await OwnableDiamond.new();
    erc165 = await DiamondERC165.new();

    const selectors = getSelectors(erc165);
    const facets = [[erc165.address, FacetAction.Add, selectors]];

    await diamond.diamondCut(facets);

    erc165 = await DiamondERC165.at(diamond.address);
  });

  describe("ERC165", () => {
    it("should support IERC165", async () => {
      assert.isTrue(await erc165.supportsInterface(web3.eth.abi.encodeFunctionSignature("supportsInterface(bytes4)")));
    });
    it("should support DiamondLoupe interface - 0x48e2b093", async () => {
      assert.isTrue(await erc165.supportsInterface("0x48e2b093"));
    });
    it("should not support DiamondCut interface until it explicitly defined in diamond", async () => {
      assert.isFalse(
        await erc165.supportsInterface(
          web3.eth.abi.encodeFunctionSignature("diamondCut((address,uint8,bytes4[])[],address,bytes)")
        )
      );
      assert.isFalse(
        await erc165.supportsInterface(web3.eth.abi.encodeFunctionSignature("diamondCut((address,uint8,bytes4[])[])"))
      );
    });
  });
});
