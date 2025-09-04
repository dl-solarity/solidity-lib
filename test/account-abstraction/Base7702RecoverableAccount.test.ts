import { expect } from "chai";
import { ethers, network } from "hardhat";

import { Base7702RecoverableAccountMock, ERC20Mock, RecoveryProviderMock } from "@/generated-types/ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { getBatchExecuteSignature } from "@/test/helpers/sign-helper";

describe("Base7702RecoverableAccount", () => {
  const reverter = new Reverter();

  let account: Base7702RecoverableAccountMock;
  let provider1: RecoveryProviderMock;
  let provider2: RecoveryProviderMock;

  let FIRST: SignerWithAddress;
  let SECOND: SignerWithAddress;
  let DELEGATED: SignerWithAddress;

  let token: ERC20Mock;

  const RECOVERY_DATA = "0x1234";

  const SINGLE_BATCH_MODE = "0x0100000000000000000000000000000000000000000000000000000000000000";
  const SINGLE_BATCH_OP_DATA_MODE = "0x0100000000007821000100000000000000000000000000000000000000000000";
  const BATCH_OF_BATCHES_MODE = "0x0100000000007821000200000000000000000000000000000000000000000000";

  before(async () => {
    [FIRST, SECOND] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    token = await ERC20Mock.deploy("Mock", "MCK", 18);

    const Account = await ethers.getContractFactory("Base7702RecoverableAccountMock");
    account = await Account.deploy();

    await FIRST.sendTransaction({
      to: await account.getAddress(),
      value: ethers.parseEther("1.0"),
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [await account.getAddress()],
    });

    DELEGATED = await ethers.getSigner(await account.getAddress());

    const RecoveryProviderMock = await ethers.getContractFactory("RecoveryProviderMock");
    provider1 = await RecoveryProviderMock.deploy();
    provider2 = await RecoveryProviderMock.deploy();

    await token.mint(FIRST, wei(100));

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("updateTrustedExecutor", () => {
    it("should add trusted executors correctly", async () => {
      expect(await account.getTrustedExecutors()).to.be.deep.eq([]);

      let tx = await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);

      await expect(tx).to.emit(account, "TrustedExecutorAdded").withArgs(FIRST.address);

      tx = await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      await expect(tx).to.emit(account, "TrustedExecutorAdded").withArgs(SECOND.address);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([FIRST.address, SECOND.address]);
    });

    it("should remove trusted executors correctly", async () => {
      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);
      await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      const tx = await account.connect(DELEGATED).updateTrustedExecutor(SECOND, false);

      await expect(tx).to.emit(account, "TrustedExecutorRemoved").withArgs(SECOND.address);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([FIRST.address]);
    });

    it("should revert if trying to add already existing executor", async () => {
      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);

      await expect(account.connect(DELEGATED).updateTrustedExecutor(FIRST, true))
        .to.be.revertedWithCustomError(account, "TrustedExecutorAlreadyAdded")
        .withArgs(FIRST.address);
    });

    it("should revert if trying to remove an executor that doesn't exist", async () => {
      await expect(account.connect(DELEGATED).updateTrustedExecutor(FIRST, false))
        .to.be.revertedWithCustomError(account, "TrustedExecutorNotRegistered")
        .withArgs(FIRST.address);
    });

    it("should revert if the function is not self called", async () => {
      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);

      await expect(account.connect(FIRST).updateTrustedExecutor(FIRST, false)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      await expect(account.connect(SECOND).updateTrustedExecutor(FIRST, false)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      const updateData = account.interface.encodeFunctionData("updateTrustedExecutor", [FIRST.address, false]);

      const calls = [[await account.getAddress(), 0, updateData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(FIRST).execute(SINGLE_BATCH_MODE, executionData)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );

      const callerContract = await ethers.deployContract("Caller");

      await expect(callerContract.connect(DELEGATED).callUpdate(account, SECOND)).to.be.revertedWithCustomError(
        account,
        "NotSelfCalled",
      );
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

      expect(await account.getTrustedExecutors()).to.be.deep.eq([]);

      const subject = ethers.AbiCoder.defaultAbiCoder().encode(["address", "bool"], [FIRST.address, true]);

      const tx = await account.connect(SECOND).recoverAccess(subject, provider1, "0x");

      await expect(tx).to.emit(account, "AccessRecovered").withArgs(subject);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([FIRST.address]);
    });

    it("should revert if recover access request is invalid", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);
      await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([SECOND.address]);

      const subject = ethers.AbiCoder.defaultAbiCoder().encode(["address", "bool"], [SECOND.address, false]);

      await expect(account.connect(FIRST).recoverAccess(subject, provider2, "0x")).to.be.reverted;

      expect(await account.getTrustedExecutors()).to.be.deep.eq([SECOND.address]);
    });
  });

  describe("execute", () => {
    it("should execute calls in single batch mode correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      const updateData = account.interface.encodeFunctionData("updateTrustedExecutor", [SECOND.address, true]);

      let calls = [[await account.getAddress(), 0, updateData]];

      let executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await account.connect(DELEGATED).execute(SINGLE_BATCH_MODE, executionData);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([SECOND.address]);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferAmount = wei(7);

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, transferAmount]);

      calls = [[await token.getAddress(), 0, transferData]];

      executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const tx = await account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData);

      await expect(tx).to.changeTokenBalances(token, [account, FIRST], [-transferAmount, transferAmount]);
    });

    it("should replace the call to address to address(this) if zero address is provided", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      const updateData = account.interface.encodeFunctionData("updateTrustedExecutor", [FIRST.address, true]);

      let calls = [[ethers.ZeroAddress, 0, updateData]];

      let executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      const tx = await account.connect(DELEGATED).execute(SINGLE_BATCH_MODE, executionData);

      await expect(tx).to.emit(account, "TrustedExecutorAdded").withArgs(FIRST.address);

      expect(await account.getTrustedExecutors()).to.be.deep.eq([FIRST.address]);
    });

    it("should execute calls with gas sponsorship correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider2.getAddress(), wei(3)]);

      const calls = [
        [await token.getAddress(), 0n, transferData1],
        [await token.getAddress(), 0n, transferData2],
      ];

      const signature = await getBatchExecuteSignature(account, FIRST, {
        calls: calls,
        nonce: 0n,
      });

      const signatureData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes"], [signature]);

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls, signatureData],
      );

      const tx = await account.connect(SECOND).execute(SINGLE_BATCH_OP_DATA_MODE, executionData);

      await expect(tx).to.changeTokenBalances(token, [account, FIRST, provider2], [-wei(8), wei(5), wei(3)]);
    });

    it("should execute calls in batch of batches mode correctly", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);
      await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider2.getAddress(), wei(1)]);
      const transferData3 = token.interface.encodeFunctionData("transfer", [await provider1.getAddress(), wei(3)]);

      const calls1 = [[await token.getAddress(), 0n, transferData1]];

      const signature1 = await getBatchExecuteSignature(account, FIRST, {
        calls: calls1,
        nonce: 0n,
      });

      const signatureData1 = ethers.AbiCoder.defaultAbiCoder().encode(["bytes"], [signature1]);

      const executionData1 = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls1, signatureData1],
      );

      const calls2 = [
        [await token.getAddress(), 0n, transferData2],
        [await token.getAddress(), 0n, transferData3],
      ];

      const signature2 = await getBatchExecuteSignature(account, SECOND, {
        calls: calls2,
        nonce: 1n,
      });

      const signatureData2 = ethers.AbiCoder.defaultAbiCoder().encode(["bytes"], [signature2]);

      const executionData2 = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls2, signatureData2],
      );

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes[]"], [[executionData1, executionData2]]);

      const tx = await account.connect(SECOND).execute(BATCH_OF_BATCHES_MODE, executionData);

      await expect(tx).to.changeTokenBalances(
        token,
        [account, FIRST, provider1, provider2],
        [-wei(9), wei(5), wei(3), wei(1)],
      );
    });

    it("should call hooks correctly", async () => {
      const Account = await ethers.getContractFactory("Base7702RecoverableAccountMockWithHooks");
      const account = await Account.deploy();

      await FIRST.sendTransaction({
        to: await account.getAddress(),
        value: ethers.parseEther("1.0"),
      });

      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [await account.getAddress()],
      });

      const DELEGATED = await ethers.getSigner(await account.getAddress());

      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);
      const transferData2 = token.interface.encodeFunctionData("transfer", [await provider1.getAddress(), wei(3)]);

      const calls = [
        [await token.getAddress(), 0n, transferData1],
        [await token.getAddress(), 0n, transferData2],
      ];

      const signature = await getBatchExecuteSignature(account, SECOND, {
        calls: calls,
        nonce: 0n,
      });

      const signatureData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes"], [signature]);

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls, signatureData],
      );

      const tx = await account.connect(SECOND).execute(SINGLE_BATCH_OP_DATA_MODE, executionData);

      await expect(tx).to.emit(account, "BeforeBatchCall").withArgs(calls, signatureData);
      await expect(tx).to.emit(account, "AfterBatchCall").withArgs(calls, signatureData);
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

    it("should revert if an unsupported mode is provided", async () => {
      const invalidMode = "0x0100000000007821000300000000000000000000000000000000000000000000";

      await expect(account.execute(invalidMode, "0x")).to.be.revertedWithCustomError(
        account,
        "UnsupportedExecutionMode",
      );
    });

    it("should revert if unsupported execution data format is provided", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await account.connect(DELEGATED).updateTrustedExecutor(FIRST, true);

      await token.connect(FIRST).transfer(account, wei(5));

      const transferData1 = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls1 = [[await token.getAddress(), 0n, transferData1]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls1]);

      const executionDataWithOpData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls1, "0x"],
      );

      const executionDataBatch = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes[]"],
        [[executionData, executionData]],
      );

      await expect(
        account.connect(FIRST).execute(SINGLE_BATCH_OP_DATA_MODE, executionData),
      ).to.be.revertedWithoutReason();
      await expect(
        account.connect(FIRST).execute(SINGLE_BATCH_OP_DATA_MODE, executionDataBatch),
      ).to.be.revertedWithoutReason();

      await expect(account.connect(FIRST).execute(BATCH_OF_BATCHES_MODE, executionData)).to.be.reverted;
      await expect(account.connect(FIRST).execute(BATCH_OF_BATCHES_MODE, executionDataWithOpData)).to.be.reverted;

      await expect(account.connect(FIRST).execute(SINGLE_BATCH_MODE, executionDataBatch)).to.be.revertedWithoutReason();

      const tx = await account.connect(FIRST).execute(SINGLE_BATCH_MODE, executionDataWithOpData);

      await expect(tx).to.changeTokenBalances(token, [account, FIRST], [-wei(5), wei(5)]);
    });

    it("should revert if the function is not self called or not called by a trusted executor", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider1, RECOVERY_DATA);

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData))
        .to.be.revertedWithCustomError(account, "NotSelfOrTrustedExecutor")
        .withArgs(SECOND.address);
    });

    it("should revert if invalid signature is provided with the sponsored transaction", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(5)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const signature = await getBatchExecuteSignature(account, SECOND, {
        calls: calls,
        nonce: 0n,
      });

      const signatureData = ethers.AbiCoder.defaultAbiCoder().encode(["bytes"], [signature]);

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["tuple(address,uint256,bytes)[]", "bytes"],
        [calls, signatureData],
      );

      await expect(account.connect(SECOND).execute(SINGLE_BATCH_OP_DATA_MODE, executionData))
        .to.be.revertedWithCustomError(account, "NotSelfOrTrustedExecutor")
        .withArgs(SECOND.address);
    });

    it("should bubble up an error from the call", async () => {
      await account.connect(DELEGATED).addRecoveryProvider(provider2, RECOVERY_DATA);

      await account.connect(DELEGATED).updateTrustedExecutor(SECOND, true);

      await token.connect(FIRST).transfer(account, wei(10));

      const transferData = token.interface.encodeFunctionData("transfer", [FIRST.address, wei(20)]);

      const calls = [[await token.getAddress(), 0n, transferData]];

      const executionData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [calls]);

      await expect(account.connect(SECOND).execute(SINGLE_BATCH_MODE, executionData))
        .to.be.revertedWithCustomError(token, "ERC20InsufficientBalance")
        .withArgs(await account.getAddress(), wei(10), wei(20));
    });
  });

  describe("supportsExecutionMode", () => {
    it("should correctly identify supported and unsupported modes", async () => {
      expect(await account.supportsExecutionMode(SINGLE_BATCH_MODE)).to.be.true;
      expect(await account.supportsExecutionMode(SINGLE_BATCH_OP_DATA_MODE)).to.be.true;
      expect(await account.supportsExecutionMode(BATCH_OF_BATCHES_MODE)).to.be.true;

      const invalidMode = "0x0100000000007821000300000000000000000000000000000000000000000000";
      expect(await account.supportsExecutionMode(invalidMode)).to.be.false;
    });
  });
});
