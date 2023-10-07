import { ethers } from "hardhat";
import { expect } from "chai";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";

import { OwnableDiamondMock, DiamondERC165, Diamond } from "@ethers-v6";

describe("DiamondERC165", () => {
  let erc165: DiamondERC165;
  let diamond: OwnableDiamondMock;

  beforeEach("setup", async () => {
    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondERC165 = await ethers.getContractFactory("DiamondERC165");

    diamond = await OwnableDiamond.deploy();
    erc165 = await DiamondERC165.deploy();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await erc165.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(erc165.interface),
      },
    ];

    await diamond.diamondCutShort(facets);

    erc165 = <DiamondERC165>DiamondERC165.attach(await diamond.getAddress());
  });

  describe("ERC165", () => {
    it("should support IERC165", async () => {
      expect(await erc165.supportsInterface(erc165.supportsInterface.fragment.selector)).to.be.true;
    });

    it("should support DiamondLoupe interface - 0x48e2b093", async () => {
      expect(await erc165.supportsInterface("0x48e2b093")).to.be.true;
    });

    it("should not support DiamondCut interface until it explicitly defined in diamond", async () => {
      expect(
        await erc165.supportsInterface(
          diamond["diamondCut((address,uint8,bytes4[])[],address,bytes)"].fragment.selector
        )
      ).to.be.false;

      expect(await erc165.supportsInterface(diamond["diamondCut((address,uint8,bytes4[])[])"].fragment.selector)).to.be
        .false;
    });
  });
});
