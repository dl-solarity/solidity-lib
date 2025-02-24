import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { getSelectors, FacetAction } from "@/test/helpers/diamond-helper";
import { wei } from "@/scripts/utils/utils";

import { OwnableDiamondMock, DiamondERC20Mock, Diamond } from "@ethers-v6";

describe("DiamondERC20 and InitializableStorage", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let erc20: DiamondERC20Mock;
  let diamond: OwnableDiamondMock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const OwnableDiamond = await ethers.getContractFactory("OwnableDiamondMock");
    const DiamondERC20Mock = await ethers.getContractFactory("DiamondERC20Mock");

    diamond = await OwnableDiamond.deploy();
    erc20 = await DiamondERC20Mock.deploy();

    const facets: Diamond.FacetStruct[] = [
      {
        facetAddress: await erc20.getAddress(),
        action: FacetAction.Add,
        functionSelectors: getSelectors(erc20.interface),
      },
    ];

    await diamond.__OwnableDiamondMock_init();
    await diamond.diamondCutShort(facets);

    erc20 = <DiamondERC20Mock>DiamondERC20Mock.attach(await diamond.getAddress());

    await erc20.__DiamondERC20Mock_init("Mock Token", "MT");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(erc20.__DiamondERC20Mock_init("Mock Token", "MT"))
        .to.be.revertedWithCustomError(erc20, "AlreadyInitialized")
        .withArgs();
    });

    it("should initialize only by top level contract", async () => {
      await expect(erc20.__DiamondERC20Direct_init("Mock Token", "MT"))
        .to.be.revertedWithCustomError(erc20, "NotInitializing")
        .withArgs();
    });

    it("should reinitialize contract correctly", async () => {
      await erc20.enableInitializers(1);

      let tx = erc20.__DiamondERC20Mock_reinit("Mock Token 2", "MT2", 2);
      await expect(tx)
        .to.emit(erc20, "Initialized")
        .withArgs(await erc20.DIAMOND_ERC20_STORAGE_SLOT(), 2);
      expect(await erc20.getInitializedVersion()).to.be.equal(2);

      tx = erc20.__DiamondERC20Mock_reinit("Mock Token 5", "MT5", 5);
      await expect(tx)
        .to.emit(erc20, "Initialized")
        .withArgs(await erc20.DIAMOND_ERC20_STORAGE_SLOT(), 5);
      expect(await erc20.getInitializedVersion()).to.be.equal(5);

      await expect(erc20.__DiamondERC20Mock_reinit("Mock Token 4", "MT4", 4))
        .to.be.revertedWithCustomError(erc20, "InvalidInitialization")
        .withArgs();

      expect(await erc20.getInitializedVersion()).to.be.equal(5);

      await expect(erc20.__DiamondERC20Mock_reinit("Mock Token 5", "MT5", 5))
        .to.be.revertedWithCustomError(erc20, "InvalidInitialization")
        .withArgs();
    });

    it("should not allow to reinitialize within the initializer", async () => {
      const DiamondERC20Mock = await ethers.getContractFactory("DiamondERC20Mock");
      const contract = await DiamondERC20Mock.deploy();

      await contract.enableInitializers(0);

      await expect(contract.__DiamondERC20Mock_reinitInit("Mock Token", "MTT", 2))
        .to.be.revertedWithCustomError(erc20, "InvalidInitialization")
        .withArgs();
    });

    it("should disable implementation initialization", async () => {
      const DiamondERC20Mock = await ethers.getContractFactory("DiamondERC20Mock");
      const contract = await DiamondERC20Mock.deploy();

      const deploymentTx = contract.deploymentTransaction();

      expect(deploymentTx)
        .to.emit(contract, "Initialized")
        .withArgs(await erc20.DIAMOND_ERC20_STORAGE_SLOT());

      await contract.enableInitializers(1);

      let disableTx = contract.disableInitializers();
      await expect(disableTx)
        .to.emit(contract, "Initialized")
        .withArgs(await erc20.DIAMOND_ERC20_STORAGE_SLOT(), 2n ** 64n - 1n);

      await expect(contract.__DiamondERC20Mock_reinit("Mock Token", "MTT", 2))
        .to.be.revertedWithCustomError(erc20, "InvalidInitialization")
        .withArgs();

      disableTx = contract.disableInitializers();
      await expect(disableTx).to.not.emit(contract, "Initialized");
    });

    it("should not allow to disable initialization within the initializer", async () => {
      const DiamondERC20Mock = await ethers.getContractFactory("DiamondERC20Mock");
      const contract = await DiamondERC20Mock.deploy();

      await contract.enableInitializers(0);

      await expect(contract.__DiamondERC20Mock_disableInit())
        .to.be.revertedWithCustomError(erc20, "InvalidInitialization")
        .withArgs();
    });
  });

  describe("DiamondERC20 functions", () => {
    it("should transfer tokens", async () => {
      await erc20.mint(OWNER.address, wei("100"));
      await erc20.transfer(SECOND.address, wei("50"));

      expect(await erc20.balanceOf(OWNER.address)).to.equal(wei("50"));
      expect(await erc20.balanceOf(SECOND.address)).to.equal(wei("50"));
    });

    it("should not transfer tokens to/from zero address", async () => {
      await expect(erc20.transferMock(SECOND.address, ethers.ZeroAddress, wei("100")))
        .to.be.revertedWithCustomError(erc20, "ReceiverIsZeroAddress")
        .withArgs();

      await expect(erc20.transferMock(ethers.ZeroAddress, SECOND.address, wei("100")))
        .to.be.revertedWithCustomError(erc20, "SenderIsZeroAddress")
        .withArgs();
    });

    it("should not transfer tokens if balance is insufficient", async () => {
      await expect(erc20.transfer(SECOND.address, wei("100")))
        .to.be.revertedWithCustomError(erc20, "InsufficientBalance")
        .withArgs(OWNER.address, erc20.balanceOf(OWNER.address), wei("100"));
    });

    it("should mint tokens", async () => {
      await erc20.mint(OWNER.address, wei("100"));

      expect(await erc20.balanceOf(OWNER.address)).to.equal(wei("100"));
    });

    it("should not mint tokens to zero address", async () => {
      await expect(erc20.mint(ethers.ZeroAddress, wei("100")))
        .to.be.revertedWithCustomError(erc20, "ReceiverIsZeroAddress")
        .withArgs();
    });

    it("should burn tokens", async () => {
      await erc20.mint(OWNER.address, wei("100"));
      await erc20.burn(OWNER.address, wei("50"));

      expect(await erc20.balanceOf(OWNER.address)).to.equal(wei("50"));
    });

    it("should not burn tokens from zero address", async () => {
      await expect(erc20.burn(ethers.ZeroAddress, wei("100")))
        .to.be.revertedWithCustomError(erc20, "SenderIsZeroAddress")
        .withArgs();
    });

    it("should not burn tokens if balance is insufficient", async () => {
      await expect(erc20.burn(OWNER.address, wei("100")))
        .to.be.revertedWithCustomError(erc20, "InsufficientBalance")
        .withArgs(OWNER.address, erc20.balanceOf(OWNER.address), wei("100"));
    });

    it("should approve tokens", async () => {
      await erc20.approve(SECOND.address, wei("100"));

      expect(await erc20.allowance(OWNER.address, SECOND.address)).to.equal(wei("100"));
    });

    it("should not approve tokens to/from zero address", async () => {
      await expect(erc20.approveMock(OWNER.address, ethers.ZeroAddress, wei("100")))
        .to.be.revertedWithCustomError(erc20, "SpenderIsZeroAddress")
        .withArgs();

      await expect(erc20.approveMock(ethers.ZeroAddress, OWNER.address, wei("100")))
        .to.be.revertedWithCustomError(erc20, "ApproverIsZeroAddress")
        .withArgs();
    });

    it("should transfer tokens from address", async () => {
      await erc20.mint(OWNER.address, wei("100"));
      await erc20.approve(SECOND.address, wei("100"));
      await erc20.connect(SECOND).transferFrom(OWNER.address, SECOND.address, wei("50"));

      expect(await erc20.balanceOf(OWNER.address)).to.equal(wei("50"));
      expect(await erc20.balanceOf(SECOND.address)).to.equal(wei("50"));
    });

    it("should not transfer tokens from address if balance is insufficient", async () => {
      await erc20.mint(OWNER.address, wei("100"));
      await erc20.approve(SECOND.address, wei("100"));

      await expect(erc20.connect(SECOND).transferFrom(OWNER.address, SECOND.address, wei("110")))
        .to.be.revertedWithCustomError(erc20, "InsufficientAllowance")
        .withArgs(SECOND.address, await erc20.allowance(OWNER.address, SECOND.address), wei("110"));
    });

    it("should not spend allowance if allowance is infinite type(uint256).max", async () => {
      await erc20.mint(OWNER.address, wei("100"));
      await erc20.approve(SECOND, ethers.MaxUint256);
      await erc20.connect(SECOND).transferFrom(OWNER.address, SECOND.address, wei("100"));

      expect(await erc20.allowance(OWNER.address, SECOND.address)).to.equal(ethers.MaxUint256);
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await erc20.name()).to.equal("Mock Token");
      expect(await erc20.symbol()).to.equal("MT");
      expect(await erc20.decimals()).to.equal(18);

      await erc20.mint(OWNER.address, wei("100"));

      expect(await erc20.balanceOf(OWNER.address)).to.equal(wei("100"));
      expect(await erc20.totalSupply()).to.equal(wei("100"));
    });
  });
});
