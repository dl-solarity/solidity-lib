import { expect } from "chai";
import hre from "hardhat";

import type { AddressLike } from "ethers";

import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { wei } from "@scripts";

import { Reverter, getSignature } from "@test-helpers";

import type {
  BridgeMock,
  ERC20CrosschainMock,
  ERC20Handler,
  MessageHandler,
  NativeHandler,
  USDCCrosschainMock,
} from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

enum ERC20BridgingType {
  LiquidityPool,
  Wrapped,
  USDCType,
}

describe("Bridge", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  const baseBalance = wei("1000");
  const baseAmount = "10";

  let OWNER: HardhatEthersSigner;
  let SECOND: HardhatEthersSigner;
  let THIRD: HardhatEthersSigner;

  let bridge: BridgeMock;
  let erc20Handler: ERC20Handler;
  let nativeHandler: NativeHandler;
  let messageHandler: MessageHandler;
  let erc20: ERC20CrosschainMock;
  let usdc: USDCCrosschainMock;

  function getTokenDispatchData(token: AddressLike, amount: bigint, type: ERC20BridgingType, batch: string = "0x") {
    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(address, uint256, string, string, bytes, uint8)"],
      [[token, amount, "receiver", "sepolia", batch, type]],
    );
  }

  function getNativeDispatchData(batch: string = "0x") {
    return ethers.AbiCoder.defaultAbiCoder().encode(["tuple(string, string, bytes)"], [["receiver", "sepolia", batch]]);
  }

  function getTokenRedeemData(
    txHash: string,
    token: AddressLike,
    amount: bigint,
    receiver: AddressLike,
    type: ERC20BridgingType,
    batch: string = "0x",
  ) {
    const nonce = ethers.keccak256(ethers.concat([ethers.toUtf8Bytes("sepolia"), txHash, ethers.toUtf8Bytes("1")]));

    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(address, uint256, address, bytes, uint8, bytes32)"],
      [[token, amount, receiver, batch, type, nonce]],
    );
  }

  function getNativeRedeemData(txHash: string, amount: bigint, receiver: AddressLike, batch: string = "0x") {
    const nonce = ethers.keccak256(ethers.concat([ethers.toUtf8Bytes("sepolia"), txHash, ethers.toUtf8Bytes("1")]));

    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(uint256, address, bytes, bytes32)"],
      [[amount, receiver, batch, nonce]],
    );
  }

  before("setup", async () => {
    [OWNER, SECOND, THIRD] = await ethers.getSigners();

    erc20Handler = await ethers.deployContract("ERC20Handler");
    nativeHandler = await ethers.deployContract("NativeHandler");
    messageHandler = await ethers.deployContract("MessageHandler");

    const Bridge = await ethers.getContractFactory("BridgeMock");
    bridge = await Bridge.deploy();

    await bridge.__BridgeMock_init(
      "sepolia",
      [1, 2, 3],
      [erc20Handler, nativeHandler, messageHandler],
      [OWNER.address],
      1,
    );

    const ERC20 = await ethers.getContractFactory("ERC20CrosschainMock");
    const USDC = await ethers.getContractFactory("USDCCrosschainMock");

    erc20 = await ERC20.deploy("Mock", "MK", 18);
    await erc20.crosschainMint(OWNER.address, baseBalance);
    await erc20.approve(await bridge.getAddress(), baseBalance);

    usdc = await USDC.deploy("Mock", "MK", 6);
    await usdc.mint(OWNER.address, wei("1000", 6));
    await usdc.approve(await bridge.getAddress(), wei("1000", 6));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("initialize", () => {
    it("should initialize correctly", async () => {
      expect(await bridge.getNetwork()).to.be.equal("sepolia");
      expect(await bridge.getHandlers()).to.be.deep.equal([
        [1n, 2n, 3n],
        [await erc20Handler.getAddress(), await nativeHandler.getAddress(), await messageHandler.getAddress()],
      ]);
      expect(await bridge.getSigners()).to.be.deep.equal([OWNER.address]);
      expect(await bridge.getBatcher()).not.to.be.equal(ethers.ZeroAddress);
      expect(await bridge.getSignaturesThreshold()).to.be.equal(1);
      expect(await bridge.assetTypeSupported(1)).to.be.true;
      expect(await bridge.assetTypeSupported(2)).to.be.true;
      expect(await bridge.assetTypeSupported(3)).to.be.true;

      await expect(bridge.mockInit()).to.be.revertedWithCustomError(bridge, "NotInitializing").withArgs();

      await expect(bridge.__BridgeMock_init("sepolia", [], [], [OWNER.address], "1"))
        .to.be.revertedWithCustomError(bridge, "InvalidInitialization")
        .withArgs();
    });
  });

  describe("ERC20 flow", () => {
    it("should dispatch 100 tokens, operationType = Wrapped", async () => {
      const expectedAmount = wei("100");

      const dispatchData = getTokenDispatchData(
        await erc20.getAddress(),
        expectedAmount,
        ERC20BridgingType.Wrapped,
        "0x01",
      );

      await bridge.dispatch(1, dispatchData);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance - expectedAmount);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);

      const dispatchEvent = (await bridge.queryFilter(erc20Handler.filters.DispatchedERC20, -1))[0];

      expect(dispatchEvent.eventName).to.be.equal("DispatchedERC20");
      expect(dispatchEvent.args.token).to.be.equal(await erc20.getAddress());
      expect(dispatchEvent.args.amount).to.be.equal(expectedAmount);
      expect(dispatchEvent.args.receiver).to.be.equal("receiver");
      expect(dispatchEvent.args.network).to.be.equal("sepolia");
      expect(dispatchEvent.args.batch).to.be.equal("0x01");
      expect(dispatchEvent.args.operationType).to.be.equal(ERC20BridgingType.Wrapped);
    });

    it("should dispatch 52 tokens, operationType = LiquidityPool", async () => {
      const expectedAmount = wei("52");

      const dispatchData = getTokenDispatchData(
        await erc20.getAddress(),
        expectedAmount,
        ERC20BridgingType.LiquidityPool,
      );

      await bridge.dispatch(1, dispatchData);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance - expectedAmount);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(expectedAmount);

      const dispatchEvent = (await bridge.queryFilter(erc20Handler.filters.DispatchedERC20, -1))[0];
      expect(dispatchEvent.args.operationType).to.be.equal(ERC20BridgingType.LiquidityPool);
    });

    it("should dispatch 50 tokens, operationType = USDCType", async () => {
      const expectedAmount = wei("50", 6);

      const dispatchData = getTokenDispatchData(await usdc.getAddress(), expectedAmount, ERC20BridgingType.USDCType);

      await bridge.dispatch(1, dispatchData);

      expect(await usdc.balanceOf(OWNER.address)).to.equal(wei("1000", 6) - expectedAmount);
      expect(await usdc.balanceOf(await bridge.getAddress())).to.equal(0);

      const dispatchEvent = (await bridge.queryFilter(erc20Handler.filters.DispatchedERC20, -1))[0];
      expect(dispatchEvent.args.operationType).to.be.equal(ERC20BridgingType.USDCType);
    });

    it("should revert if handler for the provided bridging type does not exist in dispatch", async () => {
      await bridge.removeHandler(2);

      await expect(bridge.dispatch(2, "0x")).to.be.revertedWithCustomError(bridge, "HandlerDoesNotExist").withArgs(2);
    });

    it("should revert when dispatching 0 tokens", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("0"), ERC20BridgingType.LiquidityPool);

      await expect(bridge.dispatch(1, dispatchData)).to.be.revertedWithCustomError(erc20Handler, "ZeroAmount");
    });

    it("should revert when dispatch token address is 0", async () => {
      const dispatchData = getTokenDispatchData(ethers.ZeroAddress, wei("1"), ERC20BridgingType.LiquidityPool);

      await expect(bridge.dispatch(1, dispatchData)).to.be.revertedWithCustomError(erc20Handler, "ZeroToken");
    });

    it("should redeem 100 tokens, operationType = Wrapped", async () => {
      const expectedAmount = wei("100");

      const dispatchData = getTokenDispatchData(await erc20.getAddress(), expectedAmount, ERC20BridgingType.Wrapped);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        expectedAmount,
        OWNER.address,
        ERC20BridgingType.Wrapped,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      expect(await bridge.nonceUsed(operationHash)).to.be.false;

      await bridge.redeem(1, redeemData, proof);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);

      expect(await bridge.nonceUsed(operationHash)).to.be.true;
    });

    it("should redeem 52 tokens, operationType = LiquidityPool", async () => {
      const expectedAmount = wei("52");

      const dispatchData = getTokenDispatchData(
        await erc20.getAddress(),
        expectedAmount,
        ERC20BridgingType.LiquidityPool,
      );

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        expectedAmount,
        OWNER.address,
        ERC20BridgingType.LiquidityPool,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await bridge.redeem(1, redeemData, proof);

      expect(await erc20.balanceOf(OWNER.address)).to.equal(baseBalance);
      expect(await erc20.balanceOf(await bridge.getAddress())).to.equal(0);

      expect(await bridge.nonceUsed(operationHash)).to.be.true;
    });

    it("should redeem 50 tokens, operationType = USDCType", async () => {
      const expectedAmount = wei("50", 6);

      const dispatchData = getTokenDispatchData(await usdc.getAddress(), expectedAmount, ERC20BridgingType.USDCType);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await usdc.getAddress(),
        expectedAmount,
        OWNER.address,
        ERC20BridgingType.USDCType,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await bridge.redeem(1, redeemData, proof);

      expect(await usdc.balanceOf(OWNER.address)).to.equal(wei("1000", 6));
      expect(await usdc.balanceOf(await bridge.getAddress())).to.equal(0);

      expect(await bridge.nonceUsed(operationHash)).to.be.true;
    });

    it("should redeem tokens with batch", async () => {
      const expectedAmount = wei("50");

      const dispatchData = getTokenDispatchData(
        await erc20.getAddress(),
        expectedAmount,
        ERC20BridgingType.LiquidityPool,
      );

      let tx = await bridge.dispatch(1, dispatchData);

      const transferData1 = erc20.interface.encodeFunctionData("transfer", [SECOND.address, wei("35")]);
      const transferData2 = erc20.interface.encodeFunctionData("transfer", [THIRD.address, wei("15")]);

      const batch = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address[]", "uint256[]", "bytes[]"],
        [
          [await erc20.getAddress(), await erc20.getAddress()],
          [0, 0],
          [transferData1, transferData2],
        ],
      );

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        expectedAmount,
        OWNER.address,
        ERC20BridgingType.LiquidityPool,
        batch,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      tx = await bridge.redeem(1, redeemData, proof);

      await expect(tx).to.changeTokenBalances(
        ethers,
        erc20,
        [await bridge.getAddress(), SECOND.address, THIRD.address],
        [-expectedAmount, wei("35"), wei("15")],
      );

      expect(await erc20.balanceOf(await bridge.getBatcher())).to.equal(0);
    });

    it("should revert if handler for the provided bridging type does not exist in redeem", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("2"), ERC20BridgingType.LiquidityPool);

      await bridge.dispatch(1, dispatchData);

      await expect(bridge.redeem(4, "0x", "0x"))
        .to.be.revertedWithCustomError(bridge, "HandlerDoesNotExist")
        .withArgs(4);
    });

    it("should revert when the redeem nonce is already used", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("10"), ERC20BridgingType.LiquidityPool);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        wei("10"),
        OWNER.address,
        ERC20BridgingType.LiquidityPool,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await bridge.redeem(1, redeemData, proof);

      await expect(bridge.redeem(1, redeemData, proof))
        .to.be.revertedWithCustomError(bridge, "NonceUsed")
        .withArgs(operationHash);
    });

    it("should revert when redeeming 0 tokens", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("1"), ERC20BridgingType.LiquidityPool);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        wei("0"),
        OWNER.address,
        ERC20BridgingType.LiquidityPool,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await expect(bridge.redeem(1, redeemData, proof)).to.be.revertedWithCustomError(erc20Handler, "ZeroAmount");
    });

    it("should revert when redeem token address is 0", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("1"), ERC20BridgingType.LiquidityPool);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        ethers.ZeroAddress,
        wei("0"),
        OWNER.address,
        ERC20BridgingType.LiquidityPool,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await expect(bridge.redeem(1, redeemData, proof)).to.be.revertedWithCustomError(erc20Handler, "ZeroToken");
    });

    it("should revert when receiver address is 0", async () => {
      const dispatchData = getTokenDispatchData(await erc20.getAddress(), wei("100"), ERC20BridgingType.LiquidityPool);

      const tx = await bridge.dispatch(1, dispatchData);

      const redeemData = getTokenRedeemData(
        tx.hash,
        await erc20.getAddress(),
        wei("100"),
        ethers.ZeroAddress,
        ERC20BridgingType.LiquidityPool,
      );

      const operationHash = await erc20Handler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await expect(bridge.redeem(1, redeemData, proof)).to.be.revertedWithCustomError(erc20Handler, "ZeroReceiver");
    });
  });

  describe("Native flow", () => {
    it("should dispatch native", async () => {
      const dispatchData = getNativeDispatchData("0x01");

      await bridge.dispatch(2, dispatchData, {
        value: baseAmount,
      });

      expect(await ethers.provider.getBalance(await bridge.getAddress())).to.equal(baseAmount);

      const dispatchEvent = (await bridge.queryFilter(nativeHandler.filters.DispatchedNative, -1))[0];

      expect(dispatchEvent.eventName).to.be.equal("DispatchedNative");
      expect(dispatchEvent.args.amount).to.be.equal(baseAmount);
      expect(dispatchEvent.args.receiver).to.be.equal("receiver");
      expect(dispatchEvent.args.network).to.be.equal("sepolia");
      expect(dispatchEvent.args.batch).to.be.equal("0x01");
    });

    it("should revert when dispatching 0 tokens", async () => {
      const dispatchData = getNativeDispatchData();

      await expect(bridge.dispatch(2, dispatchData)).to.be.revertedWithCustomError(nativeHandler, "ZeroAmount");
    });

    it("should redeem native", async () => {
      const dispatchData = getNativeDispatchData();

      const tx = await bridge.dispatch(2, dispatchData, {
        value: baseAmount,
      });

      const redeemData = getNativeRedeemData(tx.hash, baseAmount, OWNER.address);

      const operationHash = await nativeHandler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      expect(await bridge.nonceUsed(operationHash)).to.be.false;

      await bridge.redeem(2, redeemData, proof);

      expect(await ethers.provider.getBalance(await bridge.getAddress())).to.equal(0);
      expect(await bridge.nonceUsed(operationHash)).to.be.true;
    });

    it("should redeem native tokens with batch", async () => {
      const dispatchData = getNativeDispatchData();

      let tx = await bridge.dispatch(2, dispatchData, {
        value: baseAmount,
      });

      const batch = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address[]", "uint256[]", "bytes[]"],
        [
          [SECOND.address, THIRD.address],
          [7n, 2n],
          ["0x", "0x"],
        ],
      );

      const redeemData = getNativeRedeemData(tx.hash, BigInt(baseAmount), ethers.ZeroAddress, batch);

      const operationHash = await nativeHandler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      tx = await bridge.redeem(2, redeemData, proof);

      await expect(tx).to.changeEtherBalances(
        ethers,
        [await bridge.getAddress(), await bridge.getBatcher(), SECOND.address, THIRD.address],
        [-10, 1, 7, 2],
      );
    });

    it("should revert when redeeming 0 tokens", async () => {
      const redeemData = getNativeRedeemData("0x", wei("0"), OWNER.address);

      const operationHash = await nativeHandler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await expect(bridge.redeem(2, redeemData, proof)).to.be.revertedWithCustomError(nativeHandler, "ZeroAmount");
    });

    it("should revert when receiver address is 0", async () => {
      const redeemData = getNativeRedeemData("0x", baseAmount, ethers.ZeroAddress);

      const operationHash = await nativeHandler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      await expect(bridge.redeem(2, redeemData, proof)).to.be.revertedWithCustomError(nativeHandler, "ZeroReceiver");
    });
  });

  describe("Message flow", () => {
    it("should dispatch and redeem message", async () => {
      const batchEventData1 = bridge.interface.encodeFunctionData("emitBatchEvent", [1]);
      const batchEventData2 = bridge.interface.encodeFunctionData("emitBatchEvent", [2]);

      const batch = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address[]", "uint256[]", "bytes[]"],
        [
          [await bridge.getAddress(), await bridge.getAddress()],
          [0, 0],
          [batchEventData1, batchEventData2],
        ],
      );

      const dispatchData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(string, bytes)"], [["sepolia", batch]]);

      let tx = await bridge.dispatch(3, dispatchData);

      const dispatchEvent = (await bridge.queryFilter(messageHandler.filters.DispatchedMessage, -1))[0];

      expect(dispatchEvent.eventName).to.be.equal("DispatchedMessage");
      expect(dispatchEvent.args.network).to.be.equal("sepolia");
      expect(dispatchEvent.args.batch).to.be.equal(batch);

      const nonce = ethers.keccak256(ethers.concat([ethers.toUtf8Bytes("sepolia"), tx.hash, ethers.toUtf8Bytes("1")]));

      const redeemData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(bytes, bytes32)"], [[batch, nonce]]);

      const operationHash = await messageHandler.getOperationHash("sepolia", redeemData);

      const signature = await getSignature(ethers, OWNER, operationHash);

      const proof = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[signature]]);

      tx = await bridge.redeem(3, redeemData, proof);

      const batcher = await bridge.getBatcher();

      await expect(tx).to.emit(bridge, "BatchExecuted").withArgs(batcher, 1);
      await expect(tx).to.emit(bridge, "BatchExecuted").withArgs(batcher, 2);

      expect(await bridge.nonceUsed(operationHash)).to.be.true;
    });
  });

  describe("Signers", () => {
    it("should add signers", async () => {
      const expectedSigners = [OWNER.address, SECOND.address, THIRD.address];

      await bridge.addSigners(expectedSigners);

      expect(await bridge.getSigners()).to.be.deep.equal(expectedSigners);
    });

    it("should not add signers with 0 length", async () => {
      await expect(bridge.addSigners([])).to.be.revertedWithCustomError(bridge, "InvalidSigners").withArgs();
    });

    it("should revert when adding zero address signer", async () => {
      const expectedSigners = [OWNER.address, SECOND.address, ethers.ZeroAddress];

      await expect(bridge.addSigners(expectedSigners))
        .to.be.revertedWithCustomError(bridge, "InvalidSigner")
        .withArgs(ethers.ZeroAddress);
    });

    it("should remove signers", async () => {
      const signersToAdd = [OWNER.address, SECOND.address, THIRD.address];
      const signersToRemove = [OWNER.address, SECOND.address];

      await bridge.addSigners(signersToAdd);
      await bridge.removeSigners(signersToRemove);

      expect(await bridge.getSigners()).to.be.deep.equal([THIRD.address]);
    });

    it("should not remove signers with 0 length", async () => {
      await expect(bridge.removeSigners([])).to.be.revertedWithCustomError(bridge, "InvalidSigners").withArgs();
    });
  });

  describe("Handlers", () => {
    it("should add handler", async () => {
      await bridge.addHandler(7, erc20Handler);

      expect(await bridge.getHandlers()).to.be.deep.equal([
        [1n, 2n, 3n, 7n],
        [
          await erc20Handler.getAddress(),
          await nativeHandler.getAddress(),
          await messageHandler.getAddress(),
          await erc20Handler.getAddress(),
        ],
      ]);

      expect(await bridge.assetTypeSupported(7)).to.be.true;
    });

    it("should revert when adding handler with zero address", async () => {
      await expect(bridge.addHandler(2, ethers.ZeroAddress)).to.be.revertedWithCustomError(bridge, "ZeroHandler");
    });

    it("should revert when adding handler for the asset type that is already added", async () => {
      await expect(bridge.addHandler(2, erc20Handler))
        .to.be.revertedWithCustomError(bridge, "HandlerAlreadyPresent")
        .withArgs(2);
    });

    it("should remove handler", async () => {
      await bridge.removeHandler(2);

      expect(await bridge.getHandlers()).to.be.deep.equal([
        [1n, 3n],
        [await erc20Handler.getAddress(), await messageHandler.getAddress()],
      ]);

      expect(await bridge.assetTypeSupported(1)).to.be.true;
      expect(await bridge.assetTypeSupported(2)).to.be.false;
      expect(await bridge.assetTypeSupported(3)).to.be.true;
    });

    it("should revert when removing handler that doesn't exist", async () => {
      await expect(bridge.removeHandler(4)).to.be.revertedWithCustomError(bridge, "HandlerDoesNotExist").withArgs(4);
    });
  });

  describe("Signatures", () => {
    const signHash = "0xc4f46c912cc2a1f30891552ac72871ab0f0e977886852bdd5dccd221a595647d";

    let signersToAdd: string[];

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
      const signature1 = await getSignature(ethers, OWNER, signHash);
      const signature2 = await getSignature(ethers, SECOND, signHash);

      await expect(bridge.checkSignatures(signHash, [signature1, signature2])).to.be.eventually.fulfilled;
    });

    it("should revert when duplicate signers", async () => {
      const signature = await getSignature(ethers, OWNER, signHash);

      await expect(bridge.checkSignatures(signHash, [signature, signature]))
        .to.be.revertedWithCustomError(bridge, "DuplicateSigner")
        .withArgs(OWNER.address);
    });

    it("should revert when signed by not signer", async () => {
      await bridge.removeSigners([THIRD.address]);

      const signature = await getSignature(ethers, THIRD, signHash);

      await expect(bridge.checkSignatures(signHash, [signature]))
        .to.be.revertedWithCustomError(bridge, "InvalidSigner")
        .withArgs(THIRD.address);
    });

    it("should revert when signers < threshold", async () => {
      await expect(bridge.checkSignatures(signHash, []))
        .to.be.revertedWithCustomError(bridge, "ThresholdNotMet")
        .withArgs(0);
    });
  });
});
