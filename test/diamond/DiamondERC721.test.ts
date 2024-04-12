import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { OwnableDiamondMock, DiamondERC721Mock, Diamond } from "@ethers-v6";

describe("DiamondERC721 and InitializableStorage", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let erc721: DiamondERC721Mock;
  let diamond: OwnableDiamondMock;

  before("setup", async () => {
    [OWNER, SECOND, THIRD] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondERC721Mock = await ethers.getContractFactory("DiamondERC721Mock");

    diamond = await OwnableDiamond.deploy();
    erc721 = await DiamondERC721Mock.deploy();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await erc721.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(erc721.interface),
      },
    ];

    await diamond.__OwnableDiamondMock_init();
    await diamond.diamondCutShort(facets);

    erc721 = <DiamondERC721Mock>DiamondERC721Mock.attach(await diamond.getAddress());

    await erc721.__DiamondERC721Mock_init("Mock Token", "MT");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(erc721.__DiamondERC721Mock_init("Mock Token", "MT")).to.be.revertedWith(
        "Initializable: contract is already initialized",
      );
    });

    it("should initialize only by top level contract", async () => {
      await expect(erc721.__DiamondERC721Direct_init("Mock Token", "MT")).to.be.revertedWith(
        "Initializable: contract is not initializing",
      );
    });

    it("should disable implementation initialization", async () => {
      const DiamondERC721Mock = await ethers.getContractFactory("DiamondERC721Mock");
      const contract = await DiamondERC721Mock.deploy();

      let tx = contract.deploymentTransaction();

      expect(tx)
        .to.emit(contract, "Initialized")
        .withArgs(await erc721.DIAMOND_ERC721_STORAGE_SLOT());

      await expect(contract.disableInitializers()).to.be.revertedWith("Initializable: contract is initializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await erc721.name()).to.equal("Mock Token");
      expect(await erc721.symbol()).to.equal("MT");

      await erc721.mint(OWNER.address, 1);

      expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
      expect(await erc721.totalSupply()).to.equal(1);

      expect(await erc721.tokenOfOwnerByIndex(OWNER.address, 0)).to.equal(1);
      expect(await erc721.tokenByIndex(0)).to.equal(1);
      expect(await erc721.ownerOf(1)).to.equal(OWNER.address);

      await expect(erc721.tokenOfOwnerByIndex(OWNER.address, 10)).to.be.revertedWith(
        "ERC721Enumerable: owner index out of bounds",
      );
      await expect(erc721.tokenByIndex(10)).to.be.revertedWith("ERC721Enumerable: global index out of bounds");

      expect(await erc721.tokenURI(1)).to.equal("");
      await erc721.setBaseURI("https://example.com/");
      expect(await erc721.tokenURI(1)).to.equal("https://example.com/1");

      await expect(erc721.tokenURI(10)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("should support all necessary interfaces", async () => {
      // IERC721
      expect(await erc721.supportsInterface("0x80ac58cd")).to.be.true;
      // IERC721Metadata
      expect(await erc721.supportsInterface("0x5b5e139f")).to.be.true;
      // IERC721Enumerable
      expect(await erc721.supportsInterface("0x780e9d63")).to.be.true;
      // IERC165
      expect(await erc721.supportsInterface("0x01ffc9a7")).to.be.true;
    });
  });

  describe("DiamondERC721 functions", () => {
    describe("mint", () => {
      it("should mint tokens", async () => {
        const tx = erc721.mint(OWNER.address, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(ZERO_ADDR, OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
      });

      it("should not mint tokens to zero address", async () => {
        await expect(erc721.mint(ZERO_ADDR, 1)).to.be.revertedWith("ERC721: mint to the zero address");
      });

      it("should not mint tokens if it's alredy minted", async () => {
        await erc721.mint(OWNER.address, 1);
        await expect(erc721.mint(OWNER.address, 1)).to.be.revertedWith("ERC721: token already minted");
      });

      it("should not mint tokens if token is minted after `_beforeTokenTransfer` hook", async () => {
        await erc721.toggleReplaceOwner();

        await expect(erc721.mint(OWNER.address, 1)).to.be.revertedWith("ERC721: token already minted");
      });

      it("should not mint token if the receiver is a contract and doesn't implement onERC721Received correctly", async () => {
        const contract1 = await (await ethers.getContractFactory("DiamondERC721Mock")).deploy();

        await expect(erc721.mint(await contract1.getAddress(), 1)).to.be.revertedWith(
          "ERC721: transfer to non ERC721Receiver implementer",
        );

        const contract2 = await (await ethers.getContractFactory("NonERC721Receiver")).deploy();

        await expect(erc721.mint(await contract2.getAddress(), 1)).to.be.revertedWith(
          "ERC721Receiver: reverting onERC721Received",
        );
      });
    });

    describe("burn", () => {
      it("should burn tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);

        const tx = erc721.burn(1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, ZERO_ADDR, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
      });

      it("should not burn an incorrect token", async () => {
        await expect(erc721.burn(1)).to.be.revertedWith("ERC721: invalid token ID");
      });
    });

    describe("before token transfer hook", () => {
      it("before token transfer hook should only accept one token", async () => {
        expect(await erc721.beforeTokenTransfer(1)).not.to.be.reverted;
      });

      it("before token transfer hook should not accept more than one token", async () => {
        await expect(erc721.beforeTokenTransfer(2)).to.be.revertedWith(
          "ERC721Enumerable: consecutive transfers not supported",
        );
      });
    });

    describe("transfer/safeTransfer", () => {
      it("should transfer tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const tx = erc721.transferFrom(OWNER.address, SECOND, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(1);
      });

      it("should safely transfer tokens", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(2);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const tx = erc721.safeTransferFromMock(OWNER.address, SECOND, 1);

        await expect(tx).to.emit(erc721, "Transfer").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(1);
      });

      it("should safely transfer tokens to the contract if it implements onERC721Received correctly", async () => {
        await erc721.mint(OWNER.address, 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(1);
        expect(await erc721.balanceOf(SECOND.address)).to.equal(0);

        const receiver = await (await ethers.getContractFactory("ERC721Holder")).deploy();
        const tx = erc721.safeTransferFromMock(OWNER.address, await receiver.getAddress(), 1);

        await expect(tx)
          .to.emit(erc721, "Transfer")
          .withArgs(OWNER.address, await receiver.getAddress(), 1);

        expect(await erc721.balanceOf(OWNER.address)).to.equal(0);
        expect(await erc721.balanceOf(await receiver.getAddress())).to.equal(1);
      });

      it("should not transfer tokens when caller is not an owner or not approved", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.connect(SECOND).transferFrom(OWNER.address, SECOND.address, 1)).to.be.revertedWith(
          "ERC721: caller is not token owner or approved",
        );
        await expect(erc721.connect(SECOND).safeTransferFromMock(OWNER.address, SECOND.address, 1)).to.be.revertedWith(
          "ERC721: caller is not token owner or approved",
        );
      });

      it("should not transfer tokens when call is not an owner", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.transferFromMock(SECOND.address, OWNER.address, 1)).to.be.revertedWith(
          "ERC721: transfer from incorrect owner",
        );
      });

      it("should not transfer tokens to zero address", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.transferFromMock(OWNER.address, ZERO_ADDR, 1)).to.be.revertedWith(
          "ERC721: transfer to the zero address",
        );
      });

      it("should not transfer tokens if owner is changed after `_beforeTokenTransfer` hook", async () => {
        await erc721.mint(OWNER.address, 1);

        await erc721.toggleReplaceOwner();

        await expect(erc721.transferFromMock(OWNER.address, SECOND.address, 1)).to.be.revertedWith(
          "ERC721: transfer from incorrect owner",
        );
      });

      it("should not transfer token if the receiver is a contract and doesn't implement onERC721Received", async () => {
        await erc721.mint(OWNER.address, 1);

        const contract = await (await ethers.getContractFactory("DiamondERC721Mock")).deploy();

        await expect(erc721.safeTransferFromMock(OWNER.address, await contract.getAddress(), 1)).to.be.revertedWith(
          "ERC721: transfer to non ERC721Receiver implementer",
        );
      });
    });

    describe("approve/approveAll", () => {
      it("should approve tokens", async () => {
        await erc721.mint(OWNER.address, 1);

        const tx = erc721.approve(SECOND.address, 1);

        await expect(tx).to.emit(erc721, "Approval").withArgs(OWNER.address, SECOND.address, 1);

        expect(await erc721.getApproved(1)).to.equal(SECOND.address);
        expect(await erc721.connect(SECOND).transferFrom(OWNER.address, THIRD.address, 1)).not.to.be.reverted;

        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);
        await erc721.setApprovalForAll(SECOND.address, true);

        await erc721.connect(SECOND).approve(THIRD.address, 3);

        expect(await erc721.getApproved(3)).to.equal(THIRD.address);
        expect(await erc721.connect(THIRD).transferFrom(OWNER.address, SECOND.address, 3)).not.to.be.reverted;
      });

      it("should not approve incorrect token", async () => {
        await expect(erc721.approve(OWNER.address, 1)).to.be.revertedWith("ERC721: invalid token ID");
      });

      it("should not approve token if caller is not an owner", async () => {
        await erc721.mint(OWNER.address, 1);
        await expect(erc721.connect(SECOND).approve(THIRD.address, 1)).to.be.revertedWith(
          "ERC721: approve caller is not token owner or approved for all",
        );
      });

      it("should not approve token if spender and caller are the same", async () => {
        await erc721.mint(OWNER.address, 1);

        await expect(erc721.approve(OWNER.address, 1)).to.be.revertedWith("ERC721: approval to current owner");
      });

      it("should approve all tokens", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);
        const tx = erc721.setApprovalForAll(SECOND.address, true);

        await expect(tx).to.emit(erc721, "ApprovalForAll").withArgs(OWNER.address, SECOND.address, true);

        expect(await erc721.isApprovedForAll(OWNER.address, SECOND.address)).to.be.true;

        expect(await erc721.connect(SECOND).transferFrom(OWNER.address, THIRD.address, 1)).not.to.be.reverted;
      });

      it("should not approve all tokens if owner the same as operator", async () => {
        await erc721.mint(OWNER.address, 1);
        await erc721.mint(OWNER.address, 2);
        await erc721.mint(OWNER.address, 3);

        await expect(erc721.setApprovalForAll(OWNER.address, true)).to.be.revertedWith("ERC721: approve to caller");
      });
    });
  });
});
