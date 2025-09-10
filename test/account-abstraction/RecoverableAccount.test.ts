import { expect } from "chai";
import hre from "hardhat";

import {
  ERC20Mock,
  EntryPointMock,
  IAccount,
  RecoverableAccountMock,
  RecoveryProviderMock,
} from "@/generated-types/ethers";
import { AddressLike, HDNodeWallet, ZeroAddress } from "ethers";

import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types";

import { Reverter } from "@test-helpers";

import { wei } from "@/scripts/utils/utils";

const { ethers, networkHelpers } = await hre.network.connect();

describe("RecoverableAccount", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let account: RecoverableAccountMock;
  let provider1: RecoveryProviderMock;
  let provider2: RecoveryProviderMock;
  let entryPoint: EntryPointMock;
  let token: ERC20Mock;

  let signer: HDNodeWallet;

  let FIRST: HardhatEthersSigner;
  let SECOND: HardhatEthersSigner;
  let DELEGATED: HardhatEthersSigner;

  const callGasLimit = 2000_000n;
  const verificationGasLimit = 2000_000n;
  const maxFeePerGas = ethers.parseUnits("100", "gwei");
  const maxPriorityFeePerGas = ethers.parseUnits("100", "gwei");

  const RECOVERY_DATA = "0x1234";

  const SINGLE_BATCH_MODE = "0x0100000000000000000000000000000000000000000000000000000000000000";
  const BATCH_OF_BATCHES_MODE = "0x0100000000007821000200000000000000000000000000000000000000000000";

  async function getSignature(userOp: IAccount.PackedUserOperationStruct) {
    const userOpHash = await entryPoint.getUserOpHash(userOp);

    const signature = signer.signingKey.sign(userOpHash);

    return ethers.Signature.from(signature).serialized;
  }

  function packTwoUint128(a, b) {
    const maxUint128 = (1n << 128n) - 1n;

    if (a > maxUint128 || b > maxUint128) {
      throw new Error("Value exceeds uint128");
    }

    const packed = (a << 128n) + b;

    return "0x" + packed.toString(16).padStart(64, "0");
  }

  async function getUserOp(callData: string = "0x", accountAddress: AddressLike = ZeroAddress) {
    const accountGasLimits = packTwoUint128(callGasLimit, verificationGasLimit);
    const gasFees = packTwoUint128(maxFeePerGas, maxPriorityFeePerGas);

    if (accountAddress == ZeroAddress) {
      accountAddress = await account.getAddress();
    }

    return {
      sender: accountAddress,
      nonce: await entryPoint.getNonce(accountAddress, 0),
      initCode: "0x",
      callData: callData,
      accountGasLimits: accountGasLimits,
      preVerificationGas: 50_000n,
      gasFees: gasFees,
      paymasterAndData: "0x",
      signature: "0x",
    };
  }

  before("setup", async () => {
    [FIRST, SECOND] = await ethers.getSigners();

    signer = ethers.Wallet.createRandom().connect(ethers.provider);

    entryPoint = await ethers.deployContract("EntryPointMock");

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    token = await ERC20Mock.deploy("Mock", "MCK", 18);

    account = await ethers.deployContract("RecoverableAccountMock");

    await account.initialize(entryPoint, SECOND);

    await FIRST.sendTransaction({
      to: await account.getAddress(),
      value: ethers.parseEther("1.0"),
    });

    await networkHelpers.impersonateAccount(await account.getAddress());

    DELEGATED = await ethers.provider.getSigner(await account.getAddress());

    const RecoveryProviderMock = await ethers.getContractFactory("RecoveryProviderMock");
    provider1 = await RecoveryProviderMock.deploy();
    provider2 = await RecoveryProviderMock.deploy();

    await token.mint(FIRST, wei(100));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("initialize", () => {
    it("should not initialize twice", async () => {
      await expect(account.initialize(entryPoint, FIRST)).to.be.revertedWithCustomError(
        account,
        "InvalidInitialization",
      );

      await expect(account.callInitialize(entryPoint, FIRST)).to.be.revertedWithCustomError(account, "NotInitializing");
    });
  });

  describe("addRecoveryProvider", () => {
    it("should add a recovery provider correctly", async () => {
      expect(await account.getRecoveryProviders()).to.be.deep.equal([]);

      const tx = await account.connect(DELEGATED).addRecoveryProvider(await provider1.getAddress(), RECOVERY_DATA);

      await expect(tx)
        .to.emit(account, "RecoveryProviderAdded")
        .withArgs(await provider1.getAddress());

      expect(await account.getRecoveryProviders()).to.be.deep.equal([await provider1.getAddress()]);
    });

    it("should revert if the function is not self called", async () => {
      await expect(account.connect(FIRST).addRecoveryProvider(provider1, RECOVERY_DATA)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      const subject = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [FIRST.address]);

      await account.connect(SECOND).recoverAccess(subject, provider1, "0x");

      expect(await account.trustedExecutor()).to.be.eq(FIRST.address);

      await expect(account.connect(FIRST).addRecoveryProvider(provider2, RECOVERY_DATA)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      const addRecoveryProviderData = account.interface.encodeFunctionData("addRecoveryProvider", [
        await provider2.getAddress(),
        RECOVERY_DATA,
      ]);

      const calls = [[await account.getAddress(), 0, addRecoveryProviderData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(FIRST).execute(SINGLE_BATCH_MODE, executionData)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      const callerContract = await ethers.deployContract("Caller");

      await expect(
        callerContract.connect(DELEGATED).callAddRecoveryProvider(account, provider2, RECOVERY_DATA),
      ).to.be.revertedWithCustomError(account, "NotSelfCalled");
    });
  });

  describe("removeRecoveryProvider", () => {
    it("should remove recovery provider correctly", async () => {
      expect(await account.getRecoveryProviders()).to.be.deep.equal([]);

      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      expect(await account.getRecoveryProviders()).to.be.deep.equal([
        await provider1.getAddress(),
        await provider2.getAddress(),
      ]);

      const tx = await account.connect(DELEGATED).removeRecoveryProvider(provider1);
      await expect(tx)
        .to.emit(account, "RecoveryProviderRemoved")
        .withArgs(await provider1.getAddress());

      expect(await account.getRecoveryProviders()).to.be.deep.equal([await provider2.getAddress()]);
    });

    it("should revert if the function is not self called", async () => {
      await expect(account.connect(FIRST).removeRecoveryProvider(provider1)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );
    });
  });

  describe("recoverAccess", () => {
    it("should recover access correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      expect(await account.trustedExecutor()).to.be.eq(SECOND.address);

      let subject = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [FIRST.address]);

      let tx = await account.connect(SECOND).recoverAccess(subject, provider1, "0x");

      await expect(tx).to.emit(account, "AccessRecovered").withArgs(subject);
      await expect(tx).to.emit(account, "TrustedExecutorUpdated").withArgs(SECOND.address, FIRST.address);

      expect(await account.trustedExecutor()).to.be.eq(FIRST.address);

      subject = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [SECOND.address]);

      tx = await account.connect(SECOND).recoverAccess(subject, provider1, "0x");

      await expect(tx).to.emit(account, "AccessRecovered").withArgs(subject);
      await expect(tx).to.emit(account, "TrustedExecutorUpdated").withArgs(FIRST.address, SECOND.address);

      expect(await account.trustedExecutor()).to.be.eq(SECOND.address);
    });

    it("should revert if recover access request is invalid", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      expect(await account.trustedExecutor()).to.be.eq(SECOND.address);

      const subject = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [FIRST.address]);

      await expect(account.connect(FIRST).recoverAccess(subject, provider2, "0x"))
        .to.be.revertedWithCustomError(account, "ProviderNotRegistered")
        .withArgs(await provider2.getAddress());

      expect(await account.trustedExecutor()).to.be.eq(SECOND.address);
    });
  });

  describe("execute", () => {
    it("should execute calls in single batch mode correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      await token.connect(FIRST).transfer(account, wei(20));

      const nativeAmount = ethers.parseEther("0.2");

      let calls = [[SECOND.address, nativeAmount, "0x"]];

      let executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      let tx = await account.connect(DELEGATED).execute(SINGLE_BATCH_MODE, executionData);

      await expect(tx).to.changeEtherBalances(ethers, [account, SECOND], [-nativeAmount, nativeAmount]);

      const transferAmount = wei(7);

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, transferAmount]);

      calls = [[await token.getAddress(), 0, transferData]];

      executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      tx = await account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData);

      await expect(tx).to.changeTokenBalances(ethers, token, [account, FIRST], [-transferAmount, transferAmount]);
    });

    it("should execute calls with gas sponsorship correctly", async () => {
      const account = await ethers.deployContract("RecoverableAccountMockWithHooks");

      await account.initialize(entryPoint, signer);

      await FIRST.sendTransaction({
        to: await account.getAddress(),
        value: ethers.parseEther("1"),
      });

      await networkHelpers.impersonateAccount(await account.getAddress());

      const DELEGATED = await ethers.provider.getSigner(await account.getAddress());

      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await entryPoint.connect(FIRST).depositTo(await account.getAddress(), {
        value: wei("0.205"),
      });

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider2.getAddress(), wei(3)]);

      const calls = [
        [await token.getAddress(), 0n, transferData1],
        [await token.getAddress(), 0n, transferData2],
      ];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const callData = account.interface.encodeFunctionData("execute", [SINGLE_BATCH_MODE, executionData]);

      const userOp = await getUserOp(callData, await account.getAddress());

      userOp.signature = await getSignature(userOp);

      await networkHelpers.setBalance(await account.getAddress(), wei("0.2"));

      const secondBalance = await ethers.provider.getBalance(SECOND);

      const tx = await entryPoint.connect(SECOND).handleOps([userOp], SECOND);

      await expect(tx).to.changeTokenBalances(ethers, token, [account, FIRST, provider2], [-wei(8), wei(5), wei(3)]);

      // Compensated
      expect(await ethers.provider.getBalance(SECOND)).to.be.greaterThan(secondBalance);

      expect(await ethers.provider.getBalance(account)).to.be.eq(0);
    });

    it("should execute calls in batch of batches mode correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider2.getAddress(), wei(1)]);
      const transferData3 = token.interface.encodeFunctionData("transfer", [await provider1.getAddress(), wei(3)]);

      const calls1 = [[await token.getAddress(), 0n, transferData1]];

      const executionData1 = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls1]);

      const calls2 = [
        [await token.getAddress(), 0n, transferData2],
        [await token.getAddress(), 0n, transferData3],
      ];

      const executionData2 = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls2]);

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[executionData1, executionData2]]);

      const tx = await account.connect(SECOND).execute(BATCH_OF_BATCHES_MODE, executionData);

      await expect(tx).to.changeTokenBalances(
        ethers,
        token,
        [account, FIRST, provider1, provider2],
        [-wei(9), wei(5), wei(3), wei(1)],
      );
    });

    it("should call hooks correctly", async () => {
      const account = await ethers.deployContract("RecoverableAccountMockWithHooks");

      await account.initialize(entryPoint, SECOND);

      await FIRST.sendTransaction({
        to: await account.getAddress(),
        value: ethers.parseEther("0.5"),
      });

      await networkHelpers.impersonateAccount(await account.getAddress());

      const DELEGATED = await ethers.provider.getSigner(await account.getAddress());

      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider1.getAddress(), wei(3)]);

      const calls = [
        [await token.getAddress(), 0n, transferData1],
        [await token.getAddress(), 0n, transferData2],
      ];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const tx = await account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData);

      await expect(tx)
        .to.emit(account, "BeforeCall")
        .withArgs(await token.getAddress(), 0, transferData1);
      await expect(tx)
        .to.emit(account, "BeforeCall")
        .withArgs(await token.getAddress(), 0, transferData2);
      await expect(tx)
        .to.emit(account, "AfterCall")
        .withArgs(await token.getAddress(), 0, transferData1);
      await expect(tx)
        .to.emit(account, "AfterCall")
        .withArgs(await token.getAddress(), 0, transferData2);
    });

    it("should revert if the account cannot prefund the execute", async () => {
      const account = await ethers.deployContract("RecoverableAccountMockWithHooks");

      await account.initialize(entryPoint, signer);

      await FIRST.sendTransaction({
        to: await account.getAddress(),
        value: ethers.parseEther("3"),
      });

      await networkHelpers.impersonateAccount(await account.getAddress());

      const DELEGATED = await ethers.provider.getSigner(await account.getAddress());

      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await entryPoint.connect(FIRST).depositTo(await account.getAddress(), {
        value: wei("0.2"),
      });

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const callData = account.interface.encodeFunctionData("execute", [SINGLE_BATCH_MODE, executionData]);

      const userOp = await getUserOp(callData, await account.getAddress());

      userOp.signature = await getSignature(userOp);

      await networkHelpers.setBalance(await account.getAddress(), 0n);

      const errorInterface = new ethers.Interface(["error InsufficientBalance(uint256 balance, uint256 needed)"]);

      const encodedError = errorInterface.encodeErrorResult("InsufficientBalance", [0, wei("0.205")]);

      await expect(entryPoint.connect(SECOND).handleOps([userOp], SECOND))
        .to.be.revertedWithCustomError(entryPoint, "FailedOpWithRevert")
        .withArgs(0, "AA23 reverted", encodedError);
    });

    it("should revert if the function is not self called or not called by a trusted executor or entry point", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(FIRST).execute(SINGLE_BATCH_MODE, executionData))
        .to.be.revertedWithCustomError(account, "InvalidExecutor")
        .withArgs(FIRST.address);
    });

    it("should revert if invalid signature is provided with the sponsored transaction", async () => {
      const account = await ethers.deployContract("RecoverableAccountMockWithHooks");

      await account.initialize(entryPoint, SECOND);

      await FIRST.sendTransaction({
        to: await account.getAddress(),
        value: ethers.parseEther("2"),
      });

      await networkHelpers.impersonateAccount(await account.getAddress());

      const DELEGATED = await ethers.provider.getSigner(await account.getAddress());

      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await entryPoint.connect(FIRST).depositTo(await account.getAddress(), {
        value: ethers.parseEther("1"),
      });

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const callData = account.interface.encodeFunctionData("execute", [SINGLE_BATCH_MODE, executionData]);

      const userOp = await getUserOp(callData, await account.getAddress());

      userOp.signature = await getSignature(userOp);

      await networkHelpers.setBalance(await account.getAddress(), 0n);

      expect(await ethers.provider.getBalance(account)).to.be.eq(0);

      await expect(entryPoint.connect(SECOND).handleOps([userOp], SECOND))
        .to.be.revertedWithCustomError(entryPoint, "FailedOp")
        .withArgs(0, "AA24 signature error");
    });

    it("should bubble up an error from the call", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(20)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData))
        .to.be.revertedWithCustomError(token, "ERC20InsufficientBalance")
        .withArgs(await account.getAddress(), wei(10), wei(20));
    });
  });

  describe("validateUserOp", () => {
    it("should revert if called not by the entry point", async () => {
      const userOp = await getUserOp();
      const userOpHash = await entryPoint.getUserOpHash(userOp);

      await expect(account.connect(DELEGATED).validateUserOp(userOp, userOpHash, 1n))
        .to.be.revertedWithCustomError(account, "NotAnEntryPoint")
        .withArgs(DELEGATED.address);
    });
  });
});
