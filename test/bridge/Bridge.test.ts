import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { getSignature } from "@/test/helpers/signature";

import {
  BridgeMock,
  ERC20CrosschainMock,
  USDCCrosschainMock,
  ERC721CrosschainMock,
  ERC1155CrosschainMock,
} from "@ethers-v6";

enum ERC20BridgingType {
  LiquidityPool,
  Wrapped,
  USDCType,
}

enum ERC721BridgingType {
  LiquidityPool,
  Wrapped,
}

enum ERC1155BridgingType {
  LiquidityPool,
  Wrapped,
}

describe("Bridge", () => {
  const reverter = new Reverter();

  const baseBalance = wei("1000");
  const baseAmount = "10";
  const baseId = "5000";
  const tokenURI = "https://some.link";
  const txHash = "0xc4f46c912cc2a1f30891552ac72871ab0f0e977886852bdd5dccd221a595647d";
  const txNonce = "1794147";

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let THIRD: SignerWithAddress;

  let bridge: BridgeMock;
  let erc20: ERC20CrosschainMock;
  let usdc: USDCCrosschainMock;
  let erc721: ERC721CrosschainMock;
  let erc1155: ERC1155CrosschainMock;

  before("setup", async () => {
    [OWNER, SECOND, THIRD] = await ethers.getSigners();

    const Bridge = await ethers.getContractFactory("BridgeMock");
    bridge = await Bridge.deploy();

    await bridge.__BridgeMock_init([OWNER.address], 1);

    const ERC20 = await ethers.getContractFactory("ERC20CrosschainMock");
    const USDC = await ethers.getContractFactory("USDCCrosschainMock");
    const ERC721 = await ethers.getContractFactory("ERC721CrosschainMock");
    const ERC1155 = await ethers.getContractFactory("ERC1155CrosschainMock");

    erc20 = await ERC20.deploy("Mock", "MK", 18);
    await erc20.crosschainMint(OWNER.address, baseBalance);
    await erc20.approve(await bridge.getAddress(), baseBalance);

    usdc = await USDC.deploy("Mock", "MK", 6);
    await usdc.mint(OWNER.address, wei("1000", 6));
    await usdc.approve(await bridge.getAddress(), wei("1000", 6));

    erc721 = await ERC721.deploy("Mock", "MK", "URI");
    await erc721.crosschainMint(OWNER.address, baseId, tokenURI);
    await erc721.approve(await bridge.getAddress(), baseId);

    erc1155 = await ERC1155.deploy("Mock", "MK", "URI");
    await erc1155.crosschainMint(OWNER.address, baseId, baseAmount, tokenURI);
    await erc1155.setApprovalForAll(await bridge.getAddress(), true);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize correctly", async () => {
      await expect(bridge.mockInit()).to.be.revertedWithCustomError(bridge, "NotInitializing").withArgs();

      await expect(bridge.__BridgeMock_init([OWNER.address], "1"))
        .to.be.revertedWithCustomError(bridge, "InvalidInitialization")
        .withArgs();
    });
  });

  describe("ERC20 flow", () => {
    it("should deposit 100 tokens, operationType = Wrapped", async () => {
      const expectedAmount = wei("100");

      await bridge.depositERC20(
        await erc20.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.Wrapped,
      );

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance - expectedAmount);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC20, -1))[0];

      expect(depositEvent.eventName).to.be.equal("DepositedERC20");
      expect(depositEvent.args.token).to.be.equal(await erc20.getAddress());
      expect(depositEvent.args.amount).to.be.equal(expectedAmount);
      expect(depositEvent.args.receiver).to.be.equal("receiver");
      expect(depositEvent.args.network).to.be.equal("sepolia");
      expect(depositEvent.args.operationType).to.be.equal(ERC20BridgingType.Wrapped);
    });

    it("should deposit 52 tokens, operationType = LiquidityPool", async () => {
      let expectedAmount = wei("52");

      await bridge.depositERC20(
        await erc20.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.LiquidityPool,
      );

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance - expectedAmount);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(expectedAmount);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC20, -1))[0];
      expect(depositEvent.args.operationType).to.be.equal(ERC20BridgingType.LiquidityPool);
    });

    it("should deposit 50 tokens, operationType = USDCType", async () => {
      let expectedAmount = wei("50", 6);

      await bridge.depositERC20(
        await usdc.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.USDCType,
      );

      expect(await usdc.balanceOf(OWNER.address)).to.equal(wei("1000", 6) - expectedAmount);
      expect(await usdc.balanceOf(await bridge.getAddress())).to.equal(0);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC20, -1))[0];
      expect(depositEvent.args.operationType).to.be.equal(ERC20BridgingType.USDCType);
    });

    it("should revert when depositing 0 tokens", async () => {
      await expect(
        bridge.depositERC20(await erc20.getAddress(), wei("0"), "receiver", "sepolia", ERC20BridgingType.LiquidityPool),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidAmount")
        .withArgs();
    });

    it("should revert when token address is 0", async () => {
      await expect(
        bridge.depositERC20(ethers.ZeroAddress, wei("1"), "receiver", "sepolia", ERC20BridgingType.LiquidityPool),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should withdraw 100 tokens, operationType = Wrapped", async () => {
      let expectedAmount = wei("100");

      await bridge.depositERC20(
        await erc20.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.Wrapped,
      );
      await bridge.withdrawERC20Mock(await erc20.getAddress(), expectedAmount, OWNER, ERC20BridgingType.Wrapped);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);
    });

    it("should withdraw 52 tokens, operationType = LiquidityPool", async () => {
      let expectedAmount = wei("52");

      await bridge.depositERC20(
        await erc20.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.LiquidityPool,
      );
      await bridge.withdrawERC20Mock(await erc20.getAddress(), expectedAmount, OWNER, ERC20BridgingType.LiquidityPool);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);
    });

    it("should withdraw 50 tokens, operationType = USDCType", async () => {
      let expectedAmount = wei("50", 6);

      await bridge.depositERC20(
        await usdc.getAddress(),
        expectedAmount,
        "receiver",
        "sepolia",
        ERC20BridgingType.USDCType,
      );
      await bridge.withdrawERC20Mock(await usdc.getAddress(), expectedAmount, OWNER, ERC20BridgingType.USDCType);

      expect(await usdc.balanceOf(OWNER.address)).to.equal(wei("1000", 6));
      expect(await usdc.balanceOf(await bridge.getAddress())).to.equal(0);
    });

    it("should withdrawERC20", async () => {
      const expectedAmount = wei("100");
      const expectedOperationType = ERC20BridgingType.Wrapped;

      const signHash = await bridge.getERC20SignHash(
        await erc20.getAddress(),
        expectedAmount,
        OWNER,
        txHash,
        txNonce,
        (await ethers.provider.getNetwork()).chainId,
        expectedOperationType,
      );
      const signature = await getSignature(OWNER, signHash);

      await bridge.depositERC20(await erc20.getAddress(), expectedAmount, "receiver", "sepolia", expectedOperationType);
      await bridge.withdrawERC20(
        await erc20.getAddress(),
        expectedAmount,
        OWNER,
        txHash,
        txNonce,
        expectedOperationType,
        [signature],
      );

      expect(await erc20.balanceOf(OWNER)).to.equal(baseBalance);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);

      expect(await bridge.containsHash(txHash, txNonce)).to.be.true;
    });

    it("should revert when withdrawing 0 tokens", async () => {
      await expect(bridge.withdrawERC20Mock(await erc20.getAddress(), wei("0"), OWNER, ERC20BridgingType.LiquidityPool))
        .to.be.revertedWithCustomError(bridge, "InvalidAmount")
        .withArgs();
    });

    it("should revert when token address is 0", async () => {
      await expect(bridge.withdrawERC20Mock(ethers.ZeroAddress, wei("1"), OWNER, ERC20BridgingType.LiquidityPool))
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should revert when receiver address is 0", async () => {
      await expect(
        bridge.withdrawERC20Mock(
          await erc20.getAddress(),
          wei("100"),
          ethers.ZeroAddress,
          ERC20BridgingType.LiquidityPool,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidReceiver")
        .withArgs();
    });
  });

  describe("ERC721 flow", () => {
    it("should deposit token, operationType = Wrapped", async () => {
      await bridge.depositERC721(await erc721.getAddress(), baseId, "receiver", "sepolia", ERC721BridgingType.Wrapped);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC721, -1))[0];

      expect(depositEvent.eventName).to.be.equal("DepositedERC721");
      expect(depositEvent.args.token).to.be.equal(await erc721.getAddress());
      expect(depositEvent.args.tokenId).to.be.equal(baseId);
      expect(depositEvent.args.receiver).to.be.equal("receiver");
      expect(depositEvent.args.network).to.be.equal("sepolia");
      expect(depositEvent.args.operationType).to.be.equal(ERC721BridgingType.Wrapped);

      await expect(erc721.ownerOf(baseId))
        .to.be.revertedWithCustomError(erc721, "ERC721NonexistentToken")
        .withArgs(baseId);
    });

    it("should deposit token, operationType = LiquidityPool", async () => {
      await bridge.depositERC721(
        await erc721.getAddress(),
        baseId,
        "receiver",
        "sepolia",
        ERC721BridgingType.LiquidityPool,
      );

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC721, -1))[0];

      expect(depositEvent.args.operationType).to.be.equal(ERC721BridgingType.LiquidityPool);

      expect(await erc721.tokenURI(baseId)).to.be.equal("URI" + tokenURI);
    });

    it("should revert when token address is 0", async () => {
      await expect(
        bridge.depositERC721(ethers.ZeroAddress, baseId, "receiver", "sepolia", ERC721BridgingType.LiquidityPool),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should withdrawERC721", async () => {
      const expectedOperationType = ERC721BridgingType.Wrapped;

      const signHash = await bridge.getERC721SignHash(
        await erc721.getAddress(),
        baseId,
        OWNER,
        txHash,
        txNonce,
        (await ethers.provider.getNetwork()).chainId,
        tokenURI,
        expectedOperationType,
      );
      const signature = await getSignature(OWNER, signHash);

      await bridge.depositERC721(await erc721.getAddress(), baseId, "receiver", "sepolia", expectedOperationType);
      await bridge.withdrawERC721(
        await erc721.getAddress(),
        baseId,
        OWNER,
        txHash,
        txNonce,
        tokenURI,
        expectedOperationType,
        [signature],
      );

      expect(await erc721.ownerOf(baseId)).to.equal(OWNER.address);
      expect(await erc721.tokenURI(baseId)).to.equal("URI" + tokenURI);
    });

    it("should withdraw token, operationType = Wrapped", async () => {
      await bridge.depositERC721(await erc721.getAddress(), baseId, "receiver", "sepolia", ERC721BridgingType.Wrapped);
      await bridge.withdrawERC721Mock(await erc721.getAddress(), baseId, OWNER, tokenURI, ERC721BridgingType.Wrapped);

      expect(await erc721.ownerOf(baseId)).to.be.equal(OWNER.address);
      expect(await erc721.tokenURI(baseId)).to.be.equal("URI" + tokenURI);
    });

    it("should withdraw token, operationType = LiquidityPool", async () => {
      await bridge.depositERC721(
        await erc721.getAddress(),
        baseId,
        "receiver",
        "sepolia",
        ERC721BridgingType.LiquidityPool,
      );
      await bridge.withdrawERC721Mock(
        await erc721.getAddress(),
        baseId,
        OWNER,
        tokenURI,
        ERC721BridgingType.LiquidityPool,
      );

      expect(await erc721.ownerOf(baseId)).to.be.equal(OWNER.address);
    });

    it("should revert when token address is 0", async () => {
      await expect(
        bridge.withdrawERC721Mock(ethers.ZeroAddress, baseId, OWNER, tokenURI, ERC721BridgingType.LiquidityPool),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should revert when receiver address is 0", async () => {
      await expect(
        bridge.withdrawERC721Mock(
          await erc721.getAddress(),
          baseId,
          ethers.ZeroAddress,
          tokenURI,
          ERC721BridgingType.LiquidityPool,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidReceiver")
        .withArgs();
    });
  });

  describe("ERC1155 flow", () => {
    it("should deposit token, operationType = Wrapped", async () => {
      await bridge.depositERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        "receiver",
        "sepolia",
        ERC1155BridgingType.Wrapped,
      );

      expect(await erc1155.balanceOf(OWNER, baseId)).to.equal("0");

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC1155, -1))[0];

      expect(depositEvent.eventName).to.be.equal("DepositedERC1155");
      expect(depositEvent.args.token).to.be.equal(await erc1155.getAddress());
      expect(depositEvent.args.tokenId).to.be.equal(baseId);
      expect(depositEvent.args.amount).to.be.equal(baseAmount);
      expect(depositEvent.args.receiver).to.be.equal("receiver");
      expect(depositEvent.args.network).to.be.equal("sepolia");
      expect(depositEvent.args.operationType).to.be.equal(ERC1155BridgingType.Wrapped);
    });

    it("should deposit token, operationType = LiquidityPool", async () => {
      await bridge.depositERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        "receiver",
        "sepolia",
        ERC1155BridgingType.LiquidityPool,
      );

      expect(await erc1155.balanceOf(OWNER, baseId)).to.equal("0");
      expect(await erc1155.balanceOf(await bridge.getAddress(), baseId)).to.equal(baseAmount);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedERC1155, -1))[0];

      expect(depositEvent.args.operationType).to.be.equal(ERC1155BridgingType.LiquidityPool);

      expect(await erc1155.uri(baseId)).to.be.equal("URI" + tokenURI);
    });

    it("should revert when token address is 0", async () => {
      await expect(
        bridge.depositERC1155(
          ethers.ZeroAddress,
          baseId,
          baseAmount,
          "receiver",
          "sepolia",
          ERC1155BridgingType.LiquidityPool,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should revert when depositing 0 tokens", async () => {
      await expect(
        bridge.depositERC1155(
          await erc1155.getAddress(),
          baseId,
          "0",
          "receiver",
          "sepolia",
          ERC1155BridgingType.LiquidityPool,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidAmount")
        .withArgs();
    });

    it("should withdrawERC1155", async () => {
      const expectedOperationType = ERC1155BridgingType.Wrapped;

      const signHash = await bridge.getERC1155SignHash(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        OWNER,
        txHash,
        txNonce,
        (await ethers.provider.getNetwork()).chainId,
        tokenURI,
        expectedOperationType,
      );
      const signature = await getSignature(OWNER, signHash);

      await bridge.depositERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        "receiver",
        "sepolia",
        expectedOperationType,
      );
      await bridge.withdrawERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        OWNER,
        txHash,
        txNonce,
        tokenURI,
        expectedOperationType,
        [signature],
      );

      expect(await erc1155.balanceOf(OWNER, baseId)).to.equal(baseAmount);
      expect(await bridge.containsHash(txHash, txNonce)).to.be.true;
    });

    it("should withdraw 100 tokens, operationType = Wrapped", async () => {
      await bridge.depositERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        "receiver",
        "sepolia",
        ERC1155BridgingType.Wrapped,
      );
      await bridge.withdrawERC1155Mock(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        OWNER,
        tokenURI,
        ERC1155BridgingType.Wrapped,
      );

      expect(await erc1155.balanceOf(OWNER, baseId)).to.equal(baseAmount);
      expect(await erc1155.balanceOf(await bridge.getAddress(), baseId)).to.equal("0");
      expect(await erc1155.uri(baseId)).to.equal("URI" + tokenURI);
    });

    it("should withdraw 52 tokens, operationType = LiquidityPool", async () => {
      await bridge.depositERC1155(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        "receiver",
        "sepolia",
        ERC1155BridgingType.LiquidityPool,
      );
      await bridge.withdrawERC1155Mock(
        await erc1155.getAddress(),
        baseId,
        baseAmount,
        OWNER,
        tokenURI,
        ERC1155BridgingType.LiquidityPool,
      );

      expect(await erc1155.balanceOf(OWNER, baseId)).to.equal(baseAmount);
      expect(await erc1155.balanceOf(await bridge.getAddress(), baseId)).to.equal("0");
    });

    it("should revert when token address is 0", async () => {
      await expect(
        bridge.withdrawERC1155Mock(
          ethers.ZeroAddress,
          baseId,
          baseAmount,
          OWNER,
          tokenURI,
          ERC1155BridgingType.Wrapped,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidToken")
        .withArgs();
    });

    it("should revert when amount is 0", async () => {
      await expect(
        bridge.withdrawERC1155Mock(
          await erc1155.getAddress(),
          baseId,
          "0",
          OWNER,
          tokenURI,
          ERC1155BridgingType.Wrapped,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidAmount")
        .withArgs();
    });

    it("should revert when receiver address is 0", async () => {
      await expect(
        bridge.withdrawERC1155Mock(
          await erc1155.getAddress(),
          baseId,
          baseAmount,
          ethers.ZeroAddress,
          tokenURI,
          ERC1155BridgingType.Wrapped,
        ),
      )
        .to.be.revertedWithCustomError(bridge, "InvalidReceiver")
        .withArgs();
    });
  });

  describe("Native flow", () => {
    it("should deposit native", async () => {
      await bridge.depositNative("receiver", "sepolia", {
        value: baseAmount,
      });

      expect(await ethers.provider.getBalance(await bridge.getAddress())).to.equal(baseAmount);

      const depositEvent = (await bridge.queryFilter(bridge.filters.DepositedNative, -1))[0];

      expect(depositEvent.eventName).to.be.equal("DepositedNative");
      expect(depositEvent.args.amount).to.be.equal(baseAmount);
      expect(depositEvent.args.receiver).to.be.equal("receiver");
      expect(depositEvent.args.network).to.be.equal("sepolia");
    });

    it("should revert when depositing 0 tokens", async () => {
      await expect(bridge.depositNative("receiver", "sepolia", { value: 0 }))
        .to.be.revertedWithCustomError(bridge, "InvalidValue")
        .withArgs();
    });

    it("should withdrawNative", async () => {
      const signHash = await bridge.getNativeSignHash(
        baseBalance,
        OWNER,
        txHash,
        txNonce,
        (await ethers.provider.getNetwork()).chainId,
      );
      const signature = await getSignature(OWNER, signHash);

      await bridge.depositNative("receiver", "sepolia", { value: baseBalance });
      await bridge.withdrawNative(baseBalance, OWNER, txHash, txNonce, [signature]);

      expect(await ethers.provider.getBalance(await bridge.getAddress())).to.equal(0);
      expect(await bridge.containsHash(txHash, txNonce)).to.be.true;
    });

    it("should revert when amount is 0", async () => {
      await expect(bridge.withdrawNativeMock(0, OWNER))
        .to.be.revertedWithCustomError(bridge, "InvalidAmount")
        .withArgs();
    });

    it("should revert when receiver address is 0", async () => {
      await expect(bridge.withdrawNativeMock(baseAmount, ethers.ZeroAddress))
        .to.be.revertedWithCustomError(bridge, "InvalidReceiver")
        .withArgs();
    });
  });

  describe("Signers", () => {
    it("should add signers", async () => {
      const expectedSigners = [OWNER.address, SECOND.address, THIRD.address];

      await bridge.addSigners(expectedSigners);

      expect(await bridge.getSigners()).to.be.deep.equal(expectedSigners);
    });

    it("should not add signers with 0 length", async () => {
      expect(bridge.addSigners([])).to.be.revertedWithCustomError(bridge, "InvalidSigners").withArgs();
    });

    it("should revert when adding zero address signer", async () => {
      let expectedSigners = [OWNER.address, SECOND.address, ethers.ZeroAddress];

      expect(bridge.addSigners(expectedSigners)).to.be.revertedWithCustomError(bridge, "InvalidSigner").withArgs();
    });

    it("should remove signers", async () => {
      let signersToAdd = [OWNER.address, SECOND.address, THIRD.address];
      let signersToRemove = [OWNER.address, SECOND.address];

      await bridge.addSigners(signersToAdd);
      await bridge.removeSigners(signersToRemove);

      expect(await bridge.getSigners()).to.be.deep.equal([THIRD.address]);
    });

    it("should not remove signers with 0 length", async () => {
      expect(bridge.removeSigners([])).to.be.revertedWithCustomError(bridge, "InvalidSigners").withArgs();
    });
  });

  describe("Signatures", () => {
    let signersToAdd: string[];

    async function getSigHash() {
      let expectedTxHash = "0xc4f46c912cc2a1f30891552ac72871ab0f0e977886852bdd5dccd221a595647d";
      let expectedNonce = "1794147";

      return ethers.keccak256(
        new ethers.AbiCoder().encode(
          ["address", "uint256", "address", "bytes32", "uint256", "uint256", "bool"],
          ["0x76e98f7d84603AEb97cd1c89A80A9e914f181679", 1, OWNER.address, expectedTxHash, expectedNonce, 98, true],
        ),
      );
    }

    beforeEach("setup", async () => {
      signersToAdd = [OWNER.address, SECOND.address, THIRD.address];

      await bridge.addSigners(signersToAdd);
    });

    it("should update threshold", async () => {
      expect(await bridge.getSignaturesThreshold()).to.equal(1);

      await bridge.setSignaturesThreshold(5);

      expect(await bridge.getSignaturesThreshold()).to.equal(5);
    });

    it("should not update threshold with zero", async () => {
      await expect(bridge.setSignaturesThreshold(0))
        .to.be.revertedWithCustomError(bridge, "ThresholdIsZero")
        .withArgs();
    });

    it("should check signatures", async () => {
      const signHash = await getSigHash();

      const signature1 = await getSignature(OWNER, signHash);
      const signature2 = await getSignature(SECOND, signHash);

      await expect(bridge.checkSignatures(signHash, [signature1, signature2])).to.be.eventually.fulfilled;
    });

    it("should revert when duplicate signers", async () => {
      const signHash = await getSigHash();

      const signature = await getSignature(OWNER, signHash);

      await expect(bridge.checkSignatures(signHash, [signature, signature]))
        .to.be.revertedWithCustomError(bridge, "DuplicateSigner")
        .withArgs(OWNER.address);
    });

    it("should revert when signed by not signer", async () => {
      await bridge.removeSigners([THIRD.address]);

      const signHash = await getSigHash();

      const signature = await getSignature(THIRD, signHash);

      await expect(bridge.checkSignatures(signHash, [signature]))
        .to.be.revertedWithCustomError(bridge, "InvalidSigner")
        .withArgs(THIRD.address);
    });

    it("should revert when signers < threshold", async () => {
      const signHash = await getSigHash();

      await expect(bridge.checkSignatures(signHash, []))
        .to.be.revertedWithCustomError(bridge, "ThresholdNotMet")
        .withArgs(0);
    });
  });

  describe("Hashes", () => {
    it("should update the hash nonce", async () => {
      const txHash = "0xc4f46c912cc2a1f30891552ac72871ab0f0e977886852bdd5dccd221a595647d";
      const txNonce = "1794147";

      await bridge.checkAndUpdateHashes(txHash, txNonce);

      expect(await bridge.containsHash(txHash, txNonce)).to.be.true;
      expect(await bridge.containsHash(txHash, txNonce + 1)).to.be.false;
    });

    it("should revert when hash is added twice", async () => {
      const txHash = "0xc4f46c912cc2a1f30891552ac72871ab0f0e977886852bdd5dccd221a595647d";
      const txNonce = "1794147";

      const hash = ethers.keccak256(new ethers.AbiCoder().encode(["bytes32", "uint256"], [txHash, txNonce]));

      await bridge.checkAndUpdateHashes(txHash, txNonce);

      await expect(bridge.checkAndUpdateHashes(txHash, txNonce))
        .to.be.revertedWithCustomError(bridge, "HashNonceUsed")
        .withArgs(hash);
    });
  });
});
