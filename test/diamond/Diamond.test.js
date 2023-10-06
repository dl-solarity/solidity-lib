const { assert } = require("chai");
const { accounts, wei } = require("../../scripts/utils/utils");
const { ZERO_ADDR, ZERO_BYTES32 } = require("../../scripts/utils/constants");
const truffleAssert = require("truffle-assertions");

const OwnableDiamond = artifacts.require("OwnableDiamond");
const DummyFacet = artifacts.require("DummyFacet");
const DummyInit = artifacts.require("DummyInit");

OwnableDiamond.numberFormat = "BigNumber";
DummyFacet.numberFormat = "BigNumber";
DummyInit.numberFormat = "BigNumber";

const FacetAction = {
  Add: 0,
  Replace: 1,
  Remove: 2,
};

function getSelectors(contract) {
  return Object.keys(contract.methods).map((el) => web3.eth.abi.encodeFunctionSignature(el));
}

describe("Diamond", () => {
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
      await truffleAssert.reverts(diamond.transferOwnership(ZERO_ADDR), "OwnableDiamond: zero address owner");
    });
  });

  describe("facets", () => {
    let dummyFacet;

    beforeEach("setup", async () => {
      dummyFacet = await DummyFacet.new();
    });

    describe("getters", () => {
      it("should return empty data", async () => {
        assert.deepEqual(await diamond.facets(), []);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), []);
        assert.deepEqual(await diamond.facetAddresses(), []);
        assert.equal(await diamond.facetAddress("0x11223344"), ZERO_ADDR);
      });
    });

    describe("init", () => {
      let dummyInit;
      let init;

      let selectors;
      let facets;

      beforeEach("setup", async () => {
        dummyInit = await DummyInit.new();
        init = dummyInit.contract.methods.init().encodeABI();

        selectors = getSelectors(dummyFacet);
        facets = [[dummyFacet.address, FacetAction.Add, selectors]];
      });

      it("should init correctly", async () => {
        const tx = await diamond.diamondCut(facets, dummyInit.address, init);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return (
            ev.facets.toString() === facets.toString() && ev.initFacet === dummyInit.address && ev.initData === init
          );
        });

        const initializedIsEmitted = tx.receipt.rawLogs.some((log) => {
          return log.topics[0] == web3.utils.keccak256("Initialized()");
        });

        assert.isTrue(initializedIsEmitted);

        dummyFacet = await DummyFacet.at(diamond.address);
        assert.equal(await dummyFacet.getDummyString(), "dummy facet initialized");
      });

      it("should revert if init address is not contract", async () => {
        await truffleAssert.reverts(diamond.diamondCut(facets, SECOND, init), "Diamond: init_ address has no code");
      });

      it("should revert if init function reverted", async () => {
        const initWithError = dummyInit.contract.methods.initWithError().encodeABI();
        await truffleAssert.reverts(
          diamond.diamondCut(facets, dummyInit.address, initWithError),
          "Diamond: initialization function reverted"
        );
      });

      it("should revert if init function reverted with message", async () => {
        const initWithErrorMsg = dummyInit.contract.methods.initWithErrorMsg().encodeABI();
        await truffleAssert.reverts(
          diamond.diamondCut(facets, dummyInit.address, initWithErrorMsg),
          "DiamondInit: init error"
        );
      });
    });

    describe("add", () => {
      let facets;
      let selectors;

      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet);
        facets = [[dummyFacet.address, FacetAction.Add, selectors]];
      });

      it("should add facet correctly", async () => {
        const tx = await diamond.diamondCut(facets);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return ev.facets.toString() === facets.toString() && ev.initFacet === ZERO_ADDR && ev.initData === null;
        });

        assert.deepEqual(await diamond.facets(), [[dummyFacet.address, selectors]]);
        assert.deepEqual(await diamond.facetAddresses(), [dummyFacet.address]);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), selectors);
        assert.equal(await diamond.facetAddress(selectors[0]), dummyFacet.address);
      });

      it("should not add facet with zero address", async () => {
        facets[0][0] = ZERO_ADDR;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: facet cannot be zero address");
      });

      it("should not add non-contract as a facet", async () => {
        facets[0][0] = SECOND;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: facet is not a contract");
      });

      it("should not add facet when no selectors provided", async () => {
        facets[0][2] = [];
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: no selectors provided");
      });

      it("only owner should add facets", async () => {
        await truffleAssert.reverts(
          diamond.methods["diamondCut((address,uint8,bytes4[])[])"](facets, { from: SECOND }),
          "ODStorage: not an owner"
        );

        await truffleAssert.reverts(
          diamond.diamondCut(facets, ZERO_ADDR, ZERO_BYTES32, { from: SECOND }),
          "ODStorage: not an owner"
        );
      });

      it("should not add duplicate selectors", async () => {
        await diamond.diamondCut(facets);
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: selector already added");
      });
    });

    describe("remove", () => {
      let facets;
      let selectors;

      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet);
        facets = [[dummyFacet.address, FacetAction.Remove, selectors]];
      });

      it("should remove selectors", async () => {
        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][1] = FacetAction.Remove;
        facets[0][2] = selectors.slice(1);
        const tx = await diamond.diamondCut(facets);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return ev.facets.toString() === facets.toString() && ev.initFacet === ZERO_ADDR && ev.initData === null;
        });

        assert.deepEqual(await diamond.facets(), [[dummyFacet.address, [selectors[0]]]]);
        assert.deepEqual(await diamond.facetAddresses(), [dummyFacet.address]);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), [selectors[0]]);
        assert.equal(await diamond.facetAddress(selectors[0]), dummyFacet.address);
        assert.equal(await diamond.facetAddress(selectors[1]), ZERO_ADDR);
      });

      it("should fully remove facets", async () => {
        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][1] = FacetAction.Remove;
        const tx = await diamond.diamondCut(facets);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return ev.facets.toString() === facets.toString() && ev.initFacet === ZERO_ADDR && ev.initData === null;
        });

        assert.deepEqual(await diamond.facets(), []);
        assert.deepEqual(await diamond.facetAddresses(), []);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), []);
        assert.equal(await diamond.facetAddress(selectors[0]), ZERO_ADDR);
      });

      it("should not remove facet when facet is zero address", async () => {
        facets[0][0] = ZERO_ADDR;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: facet cannot be zero address");
      });

      it("should not remove facet when no selectors provided", async () => {
        facets[0][2] = [];
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: no selectors provided");
      });

      it("should not remove selectors from another facet", async () => {
        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][0] = diamond.address;
        facets[0][1] = FacetAction.Remove;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: selector from another facet");
      });

      it("only owner should remove facets", async () => {
        await truffleAssert.reverts(
          diamond.methods["diamondCut((address,uint8,bytes4[])[])"](facets, { from: SECOND }),
          "ODStorage: not an owner"
        );

        await truffleAssert.reverts(
          diamond.diamondCut(facets, ZERO_ADDR, ZERO_BYTES32, { from: SECOND }),
          "ODStorage: not an owner"
        );
      });
    });

    describe("replace", () => {
      let facets;
      let selectors;

      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet);
        facets = [[dummyFacet.address, FacetAction.Replace, selectors]];
      });

      it("should replace facets and and part of its selectors", async () => {
        const dummyFacet2 = await DummyFacet.new();

        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][0] = dummyFacet2.address;
        facets[0][1] = FacetAction.Replace;
        facets[0][2] = selectors.slice(1);
        const tx = await diamond.diamondCut(facets);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return ev.facets.toString() === facets.toString() && ev.initFacet === ZERO_ADDR && ev.initData === null;
        });

        assert.deepEqual(await diamond.facets(), [
          [dummyFacet.address, [selectors[0]]],
          [dummyFacet2.address, selectors.slice(1)],
        ]);

        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), [selectors[0]]);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet2.address), selectors.slice(1));

        assert.equal(await diamond.facetAddress(selectors[0]), dummyFacet.address);
        assert.equal(await diamond.facetAddress(selectors[1]), dummyFacet2.address);
      });

      it("should replace facets and all its selectors", async () => {
        const dummyFacet2 = await DummyFacet.new();

        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][0] = dummyFacet2.address;
        facets[0][1] = FacetAction.Replace;
        const tx = await diamond.diamondCut(facets);

        truffleAssert.eventEmitted(tx, "DiamondCut", (ev) => {
          return ev.facets.toString() === facets.toString() && ev.initFacet === ZERO_ADDR && ev.initData === null;
        });

        assert.deepEqual(await diamond.facets(), [[dummyFacet2.address, selectors]]);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet.address), []);
        assert.deepEqual(await diamond.facetFunctionSelectors(dummyFacet2.address), selectors);
        assert.equal(await diamond.facetAddress(selectors[0]), dummyFacet2.address);
      });

      it("should not replace facet when facet is zero address", async () => {
        facets[0][0] = ZERO_ADDR;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: facet cannot be zero address");
      });

      it("should not add non-contract as a facet", async () => {
        facets[0][0] = SECOND;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: facet is not a contract");
      });

      it("should not replace facet when no selectors provided", async () => {
        facets[0][2] = [];
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: no selectors provided");
      });

      it("should not replace facet with the same facet", async () => {
        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][1] = FacetAction.Replace;
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: cannot replace to the same facet");
      });

      it("should not replace facet if selector is not registered", async () => {
        facets[0][1] = FacetAction.Add;
        await diamond.diamondCut(facets);

        facets[0][1] = FacetAction.Replace;
        // set random selector
        facets[0][2] = ["0x00000000"];
        await truffleAssert.reverts(diamond.diamondCut(facets), "Diamond: no facet found for selector");
      });

      it("only owner should update facets", async () => {
        await truffleAssert.reverts(
          diamond.methods["diamondCut((address,uint8,bytes4[])[])"](facets, { from: SECOND }),
          "ODStorage: not an owner"
        );

        await truffleAssert.reverts(
          diamond.diamondCut(facets, ZERO_ADDR, ZERO_BYTES32, { from: SECOND }),
          "ODStorage: not an owner"
        );
      });
    });

    describe("call", () => {
      let facets;
      let selectors;

      beforeEach("setup", async () => {
        selectors = getSelectors(dummyFacet);
        facets = [[dummyFacet.address, FacetAction.Add, selectors]];
      });

      it("should be able to call facets", async () => {
        await diamond.diamondCut(facets);

        const facet = await DummyFacet.at(diamond.address);

        await facet.setDummyString("hello, diamond");

        assert.equal(await facet.getDummyString(), "hello, diamond");
        assert.equal(await dummyFacet.getDummyString(), "");
      });

      it("should receive ether via receive", async () => {
        facets[0][0] = dummyFacet.address;
        facets[0][2] = ["0x00000000"]; // recieve selector
        await diamond.diamondCut(facets);

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
        await diamond.diamondCut(facets);

        const facet = await DummyFacet.at(diamond.address);

        await truffleAssert.reverts(
          facet.setDummyString("hello, diamond", { value: wei("1") }),
          "Transaction reverted: non-payable function was called with value 1000000000000000000"
        );
      });
    });
  });
});
