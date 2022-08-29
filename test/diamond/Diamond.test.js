const { assert } = require("chai");
const { accounts, wei } = require("../../scripts/helpers/utils");
const truffleAssert = require("truffle-assertions");

const OwnableDiamond = artifacts.require("OwnableDiamond");
const DummyFacet = artifacts.require("DummyFacet");

OwnableDiamond.numberFormat = "BigNumber";
DummyFacet.numberFormat = "BigNumber";

function getSelectors(contract) {
  return Object.keys(contract.methods).map((el) => web3.eth.abi.encodeFunctionSignature(el));
}

describe("Diamond", () => {
  let ZERO = "0x0000000000000000000000000000000000000000";
  let OWNER;
  let SECOND;

  let diamond;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    diamond = await OwnableDiamond.new();
  });

  describe("ownable diamond functions", () => {
    it("should set owner correctly", async () => {
      assert.equal(await diamond.owner(), OWNER);
    });

    it("should transfer ownership", async () => {
      await diamond.transferOwnership(SECOND);

      assert.equal(await diamond.owner(), SECOND);
    });

    it("should not transfer ownership from non-owner", async () => {
      await truffleAssert.reverts(diamond.transferOwnership(SECOND, { from: SECOND }), "ODStorage: not an owner");
    });

    it("should not transfer ownership to zero address", async () => {
      await truffleAssert.reverts(diamond.transferOwnership(ZERO), "OwnableDiamond: zero address owner");
    });
  });

  describe("facets", () => {
    let dummyFacet;

    beforeEach("setup", async () => {
      dummyFacet = await DummyFacet.new();
    });

    describe("getters", () => {
      it("should return empty data", async () => {
        assert.deepEqual(await diamond.getFacets(), []);
        assert.deepEqual(await diamond.getFacetSelectors(dummyFacet.address), []);
        assert.equal(await diamond.getFacetBySelector("0x11223344"), ZERO);
      });
    });

    describe("add", () => {
      it("should add facet correctly", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);

        assert.deepEqual(await diamond.getFacets(), [dummyFacet.address]);
        assert.deepEqual(await diamond.getFacetSelectors(dummyFacet.address), selectors);
        assert.equal(await diamond.getFacetBySelector(selectors[0]), dummyFacet.address);
      });

      it("should not add non-contract as a facet", async () => {
        await truffleAssert.reverts(diamond.addFacet(SECOND, []), "Diamond: facet is not a contract");
      });

      it("should not add facet when no selectors provided", async () => {
        await truffleAssert.reverts(diamond.addFacet(dummyFacet.address, []), "Diamond: no selectors provided");
      });

      it("only owner should add facets", async () => {
        await truffleAssert.reverts(
          diamond.addFacet(dummyFacet.address, [], { from: SECOND }),
          "ODStorage: not an owner"
        );
      });

      it("should not add duplicate selectors", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);
        await truffleAssert.reverts(diamond.addFacet(dummyFacet.address, selectors), "Diamond: selector already added");
      });
    });

    describe("call", () => {
      it("should be able to call facets", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);

        const facet = await DummyFacet.at(diamond.address);

        await facet.setDummyString("hello, diamond");

        assert.equal(await facet.getDummyString(), "hello, diamond");
        assert.equal(await dummyFacet.getDummyString(), "");
      });

      it("should receive ether via receive", async () => {
        await diamond.addFacet(dummyFacet.address, ["0x00000000"]);

        await truffleAssert.passes(
          web3.eth.sendTransaction({
            to: diamond.address,
            from: OWNER,
            value: wei("1"),
          }),
          "passes"
        );
      });

      it("should not call facet if selector is not added", async () => {
        const facet = await DummyFacet.at(diamond.address);

        await truffleAssert.reverts(facet.getDummyString(), "Diamond: selector is not registered");
      });

      it("should not receive ether if receive is not added", async () => {
        await truffleAssert.reverts(
          web3.eth.sendTransaction({
            to: diamond.address,
            from: OWNER,
            value: wei("1"),
          }),
          "Diamond: selector is not registered"
        );
      });

      it("should revert if value > 0 and function is not payable", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);

        const facet = await DummyFacet.at(diamond.address);

        await truffleAssert.reverts(
          facet.setDummyString("hello, diamond", { value: wei("1") }),
          "Transaction reverted: non-payable function was called with value 1000000000000000000"
        );
      });
    });

    describe("remove", () => {
      it("should remove selectors", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);
        await diamond.removeFacet(dummyFacet.address, selectors.slice(1));

        assert.deepEqual(await diamond.getFacets(), [dummyFacet.address]);
        assert.deepEqual(await diamond.getFacetSelectors(dummyFacet.address), [selectors[0]]);
        assert.equal(await diamond.getFacetBySelector(selectors[0]), dummyFacet.address);
        assert.equal(await diamond.getFacetBySelector(selectors[1]), ZERO);
      });

      it("should not remove facet when no selectors provided", async () => {
        await truffleAssert.reverts(diamond.removeFacet(dummyFacet.address, []), "Diamond: no selectors provided");
      });

      it("should fully remove facets", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);
        await diamond.removeFacet(dummyFacet.address, selectors);

        assert.deepEqual(await diamond.getFacets(), []);
        assert.deepEqual(await diamond.getFacetSelectors(dummyFacet.address), []);
        assert.equal(await diamond.getFacetBySelector(selectors[0]), ZERO);
      });

      it("should not remove selectors from another facet", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);

        await truffleAssert.reverts(
          diamond.removeFacet(diamond.address, selectors),
          "Diamond: selector from another facet"
        );
      });

      it("only owner should remove facets", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, selectors);

        await truffleAssert.reverts(
          diamond.removeFacet(dummyFacet.address, selectors, { from: SECOND }),
          "ODStorage: not an owner"
        );
      });
    });

    describe("update", () => {
      it("should update facets", async () => {
        let selectors = getSelectors(dummyFacet);

        await diamond.addFacet(dummyFacet.address, [selectors[0]]);
        await diamond.updateFacet(dummyFacet.address, [selectors[0]], [selectors[1]]);

        assert.deepEqual(await diamond.getFacetSelectors(dummyFacet.address), [selectors[1]]);
        assert.equal(await diamond.getFacetBySelector(selectors[0]), ZERO);
        assert.equal(await diamond.getFacetBySelector(selectors[1]), dummyFacet.address);
      });

      it("only owner should update facets", async () => {
        await truffleAssert.reverts(
          diamond.updateFacet(dummyFacet.address, [], [], { from: SECOND }),
          "ODStorage: not an owner"
        );
      });
    });
  });
});
