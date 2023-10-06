import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { getSelectors } from "@/test/helpers/diamond-helper";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { wei } from "@/scripts/utils/utils";

import { OwnableDiamond, DummyFacet } from "@ethers-v6";

describe("Diamond", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let diamond: OwnableDiamond;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamond");
    diamond = await OwnableDiamond.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("ownable diamond functions", () => {
    it("should set owner correctly", async () => {
      expect(await diamond.owner()).to.equal(OWNER);
    });

    it("should transfer ownership", async () => {
      await diamond.transferOwnership(SECOND);

      expect(await diamond.owner()).to.equal(SECOND);
    });

    it("should not transfer ownership from non-owner", async () => {
      await expect(diamond.connect(SECOND).transferOwnership(SECOND)).to.be.revertedWith("ODStorage: not an owner");
    });

    it("should not transfer ownership to zero address", async () => {
      await expect(diamond.transferOwnership(ZERO_ADDR)).to.be.revertedWith("OwnableDiamond: zero address owner");
    });
  });

  describe("facets", () => {
    let dummyFacet: DummyFacet;

    beforeEach("setup", async () => {
      const DummyFacet = await ethers.getContractFactory("DummyFacet");
      dummyFacet = await DummyFacet.deploy();
    });

    describe("getters", () => {
      it("should return empty data", async () => {
        expect(await diamond.getFacets()).to.equal([]);
        expect(await diamond.getFacetSelectors(await dummyFacet.getAddress())).to.equal([]);
        expect(await diamond.getFacetBySelector("0x11223344")).to.equal(ZERO_ADDR);
      });
    });

    describe("add", () => {
      it("should add facet correctly", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);

        expect(await diamond.getFacets()).to.equal([await dummyFacet.getAddress()]);
        expect(await diamond.getFacetSelectors(await dummyFacet.getAddress())).to.equal(selectors);
        expect(await diamond.getFacetBySelector(selectors[0])).to.equal(await dummyFacet.getAddress());
      });

      it("should not add non-contract as a facet", async () => {
        await expect(diamond.addFacet(SECOND, [])).to.be.revertedWith("Diamond: facet is not a contract");
      });

      it("should not add facet when no selectors provided", async () => {
        await expect(diamond.addFacet(await dummyFacet.getAddress(), [])).to.be.revertedWith(
          "Diamond: no selectors provided"
        );
      });

      it("only owner should add facets", async () => {
        await expect(diamond.connect(SECOND).addFacet(await dummyFacet.getAddress(), [])).to.be.revertedWith(
          "ODStorage: not an owner"
        );
      });

      it("should not add duplicate selectors", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);
        await expect(diamond.addFacet(await dummyFacet.getAddress(), selectors)).to.be.revertedWith(
          "Diamond: selector already added"
        );
      });
    });

    describe("call", () => {
      it("should be able to call facets", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);

        const DummyFacet = await ethers.getContractFactory("DummyFacet");
        const facet = <DummyFacet>await DummyFacet.attach(await diamond.getAddress());

        await facet.setDummyString("hello, diamond");

        expect(await facet.getDummyString()).to.equal("hello, diamond");
        expect(await dummyFacet.getDummyString()).to.equal("");
      });

      it("should receive ether via receive", async () => {
        await diamond.addFacet(await dummyFacet.getAddress(), ["0x00000000"]);

        let tx = new ethers.Transaction();

        tx.to = await diamond.getAddress();
        tx.value = wei("1");

        await OWNER.sendTransaction(tx);
      });

      it("should not call facet if selector is not added", async () => {
        const DummyFacet = await ethers.getContractFactory("DummyFacet");
        const facet = <DummyFacet>await DummyFacet.attach(await diamond.getAddress());

        await expect(facet.getDummyString()).to.be.revertedWith("Diamond: selector is not registered");
      });

      it("should not receive ether if receive is not added", async () => {
        let tx = new ethers.Transaction();

        tx.to = await diamond.getAddress();
        tx.value = wei("1");

        await expect(OWNER.sendTransaction(tx)).to.be.revertedWith("Diamond: selector is not registered");
      });
    });

    describe("remove", () => {
      it("should remove selectors", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);
        await diamond.removeFacet(await dummyFacet.getAddress(), selectors.slice(1));

        expect(await diamond.getFacets()).to.equal([await dummyFacet.getAddress()]);
        expect(await diamond.getFacetSelectors(await dummyFacet.getAddress())).to.equal([selectors[0]]);
        expect(await diamond.getFacetBySelector(selectors[0])).to.equal(await dummyFacet.getAddress());
        expect(await diamond.getFacetBySelector(selectors[1])).to.equal(ZERO_ADDR);
      });

      it("should not remove facet when no selectors provided", async () => {
        await expect(diamond.removeFacet(await dummyFacet.getAddress(), [])).to.be.revertedWith(
          "Diamond: no selectors provided"
        );
      });

      it("should fully remove facets", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);
        await diamond.removeFacet(await dummyFacet.getAddress(), selectors);

        expect(await diamond.getFacets()).to.equal([]);
        expect(await diamond.getFacetSelectors(await dummyFacet.getAddress())).to.equal([]);
        expect(await diamond.getFacetBySelector(selectors[0])).to.equal(ZERO_ADDR);
      });

      it("should not remove selectors from another facet", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);

        await expect(diamond.removeFacet(await diamond.getAddress(), selectors)).to.be.revertedWith(
          "Diamond: selector from another facet"
        );
      });

      it("only owner should remove facets", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), selectors);

        await expect(diamond.connect(SECOND).removeFacet(await dummyFacet.getAddress(), selectors)).to.be.revertedWith(
          "ODStorage: not an owner"
        );
      });
    });

    describe("update", () => {
      it("should update facets", async () => {
        let selectors = getSelectors(dummyFacet.interface);

        await diamond.addFacet(await dummyFacet.getAddress(), [selectors[0]]);
        await diamond.updateFacet(await dummyFacet.getAddress(), [selectors[0]], [selectors[1]]);

        expect(await diamond.getFacetSelectors(await dummyFacet.getAddress())).to.equal([selectors[1]]);
        expect(await diamond.getFacetBySelector(selectors[0])).to.equal(ZERO_ADDR);
        expect(await diamond.getFacetBySelector(selectors[1])).to.equal(await dummyFacet.getAddress());
      });

      it("only owner should update facets", async () => {
        await expect(diamond.connect(SECOND).updateFacet(await dummyFacet.getAddress(), [], [])).to.be.revertedWith(
          "ODStorage: not an owner"
        );
      });
    });
  });
});
