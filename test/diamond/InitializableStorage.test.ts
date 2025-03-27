import { ethers } from "hardhat";
import { expect } from "chai";

import { Reverter } from "@/test/helpers/reverter";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { InitializableStorageMock, InitializableStorageMock__factory } from "@/generated-types/ethers";

describe("InitializableStorage", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let Mock: InitializableStorageMock__factory;
  let mock: InitializableStorageMock;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    Mock = await ethers.getContractFactory("InitializableStorageMock");
    mock = await Mock.deploy();

    await mock.__mockInitializer_init();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("init", () => {
    it("should initialize only once", async () => {
      await expect(mock.__mockInitializer_init()).to.be.revertedWithCustomError(mock, "AlreadyInitialized").withArgs();
    });

    it("should not initialize", async () => {
      await expect(mock.__mockOnlyInitializing_init())
        .to.be.revertedWithCustomError(mock, "NotInitializing")
        .withArgs();
    });

    it("should reinitialize", async () => {
      const newVersion = 2;

      await expect(mock.__mock_reinitializer(newVersion)).to.not.be.reverted;
    });

    it("should not reinitialize", async () => {
      const invalidVersion = 1;

      await expect(mock.__mock_reinitializer(invalidVersion))
        .to.be.revertedWithCustomError(mock, "InvalidInitialization")
        .withArgs();

      const newMock = await Mock.deploy();
      const validVersion = 2;

      await expect(newMock.invalidReinitializer(validVersion))
        .to.be.revertedWithCustomError(mock, "InvalidInitialization")
        .withArgs();
    });

    it("should disable initialization correctly", async () => {
      const newMock = await Mock.deploy();

      await expect(newMock.invalidDisableInitializers())
        .to.be.revertedWithCustomError(newMock, "InvalidInitialization")
        .withArgs();

      await newMock.disableInitializers();

      await expect(newMock.__mockInitializer_init())
        .to.be.revertedWithCustomError(newMock, "AlreadyInitialized")
        .withArgs();

      await newMock.disableInitializers();
    });
  });
});
