import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { ContractsRegistry1, CRDependant, CRDependantUpgrade, ERC20Mock } from "@ethers-v6";

describe("ContractsRegistry", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let contractsRegistry: ContractsRegistry1;

  before("setup", async () => {
    [OWNER, SECOND] = await ethers.getSigners();

    const ContractsRegistry1 = await ethers.getContractFactory("ContractsRegistry1");
    contractsRegistry = await ContractsRegistry1.deploy();

    await contractsRegistry.__OwnableContractsRegistry_init();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(contractsRegistry.mockInit()).to.be.revertedWith("Initializable: contract is not initializing");
      await expect(contractsRegistry.__OwnableContractsRegistry_init()).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });

    it("only owner should call these functions", async () => {
      await expect(contractsRegistry.connect(SECOND).injectDependencies("")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).injectDependenciesWithData("", "0x")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).upgradeContract("", ZERO_ADDR)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).upgradeContractAndCall("", ZERO_ADDR, "0x")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).addContract("", ZERO_ADDR)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).addProxyContract("", ZERO_ADDR)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).addProxyContractAndCall("", ZERO_ADDR, "0x")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).justAddProxyContract("", ZERO_ADDR)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(contractsRegistry.connect(SECOND).removeContract("")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("contract management", async () => {
    it("should fail adding ZERO_ADDR address", async () => {
      await expect(
        contractsRegistry.addContract(await contractsRegistry.CRDEPENDANT_NAME(), ZERO_ADDR)
      ).to.be.revertedWith("ContractsRegistry: zero address is forbidden");

      await expect(
        contractsRegistry.addProxyContract(await contractsRegistry.CRDEPENDANT_NAME(), ZERO_ADDR)
      ).to.be.revertedWith("ContractsRegistry: zero address is forbidden");

      await expect(
        contractsRegistry.justAddProxyContract(await contractsRegistry.CRDEPENDANT_NAME(), ZERO_ADDR)
      ).to.be.revertedWith("ContractsRegistry: zero address is forbidden");
    });

    it("should add and remove the contract", async () => {
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const dependant = await CRDependant.deploy();

      await expect(contractsRegistry.removeContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.revertedWith(
        "ContractsRegistry: this mapping doesn't exist"
      );

      await contractsRegistry.addContract(await contractsRegistry.CRDEPENDANT_NAME(), await dependant.getAddress());

      expect(await contractsRegistry.getCRDependantContract()).to.equal(await dependant.getAddress());
      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.CRDEPENDANT_NAME());

      await expect(contractsRegistry.getCRDependantContract()).to.be.revertedWith(
        "ContractsRegistry: this mapping doesn't exist"
      );
      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.false;
    });

    it("should add and remove the proxy contract", async () => {
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const _dependant = await CRDependant.deploy();

      await expect(contractsRegistry.getImplementation(await contractsRegistry.CRDEPENDANT_NAME())).to.be.revertedWith(
        "ContractsRegistry: this mapping doesn't exist"
      );

      await contractsRegistry.addProxyContract(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependant.getAddress()
      );

      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.CRDEPENDANT_NAME());

      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.false;
    });

    it("should add and remove proxy without dependant", async () => {
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
      const _token = await ERC20Mock.deploy("Mock", "Mock", 18);

      await contractsRegistry.addProxyContractAndCall(
        await contractsRegistry.TOKEN_NAME(),
        await _token.getAddress(),
        "0x"
      );
      await contractsRegistry.removeContract(await contractsRegistry.TOKEN_NAME());
    });

    it("should just add and remove the proxy contract", async () => {
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const _dependant = await CRDependant.deploy();

      await contractsRegistry.addProxyContract(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependant.getAddress()
      );

      const crdProxyAddr = await contractsRegistry.getCRDependantContract();

      await contractsRegistry.removeContract(await contractsRegistry.CRDEPENDANT_NAME());

      await contractsRegistry.justAddProxyContract(await contractsRegistry.CRDEPENDANT_NAME(), crdProxyAddr);

      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.true;

      await contractsRegistry.removeContract(await contractsRegistry.CRDEPENDANT_NAME());

      expect(await contractsRegistry.hasContract(await contractsRegistry.CRDEPENDANT_NAME())).to.be.false;
    });
  });

  describe("contract upgrades", () => {
    let _dependant: CRDependant;
    let _dependantUpgrade: CRDependantUpgrade;

    let dependant: CRDependantUpgrade;

    beforeEach("setup", async () => {
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const CRDependantUpgrade = await ethers.getContractFactory("CRDependantUpgrade");

      _dependant = await CRDependant.deploy();
      _dependantUpgrade = await CRDependantUpgrade.deploy();

      await contractsRegistry.addProxyContract(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependant.getAddress()
      );

      dependant = <CRDependantUpgrade>await CRDependantUpgrade.attach(await contractsRegistry.getCRDependantContract());
    });

    it("should not upgrade non-proxy contract", async () => {
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const dependant = await CRDependant.deploy();

      await contractsRegistry.addContract(await contractsRegistry.CRDEPENDANT_NAME(), await dependant.getAddress());

      await expect(contractsRegistry.getImplementation(await contractsRegistry.CRDEPENDANT_NAME())).to.be.revertedWith(
        "ContractsRegistry: not a proxy contract"
      );

      await expect(
        contractsRegistry.upgradeContract(
          await contractsRegistry.CRDEPENDANT_NAME(),
          await _dependantUpgrade.getAddress()
        )
      ).to.be.revertedWith("ContractsRegistry: not a proxy contract");
    });

    it("should upgrade the contract", async () => {
      await expect(dependant.addedFunction()).to.be.reverted;

      expect(await contractsRegistry.getImplementation(await contractsRegistry.CRDEPENDANT_NAME())).to.equal(
        await _dependant.getAddress()
      );

      await contractsRegistry.upgradeContract(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependantUpgrade.getAddress()
      );

      expect(await contractsRegistry.getImplementation(await contractsRegistry.CRDEPENDANT_NAME())).to.equal(
        await _dependantUpgrade.getAddress()
      );

      expect(await dependant.addedFunction()).to.equal(42n);
    });

    it("should not upgrade non existing contract", async () => {
      await expect(
        contractsRegistry.upgradeContract("RANDOM CONTRACT", await _dependantUpgrade.getAddress())
      ).to.be.revertedWith("ContractsRegistry: this mapping doesn't exist");
    });

    it("should upgrade and call the contract", async () => {
      await expect(dependant.addedFunction()).to.be.reverted;

      let data = _dependantUpgrade.interface.encodeFunctionData("doUpgrade", [42]);

      await contractsRegistry.upgradeContractAndCall(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependantUpgrade.getAddress(),
        data
      );

      expect(await dependant.dummyValue()).to.equal(42n);
    });
  });

  describe("dependency injection", () => {
    let dependant: CRDependantUpgrade;
    let token: ERC20Mock;

    beforeEach("setup", async () => {
      const CRDependantUpgrade = await ethers.getContractFactory("CRDependantUpgrade");
      const CRDependant = await ethers.getContractFactory("CRDependant");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      const _dependant = await CRDependant.deploy();
      token = await ERC20Mock.deploy("Mock", "Mock", 18);

      await contractsRegistry.addProxyContract(
        await contractsRegistry.CRDEPENDANT_NAME(),
        await _dependant.getAddress()
      );

      await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());

      dependant = <CRDependantUpgrade>await CRDependantUpgrade.attach(await contractsRegistry.getCRDependantContract());
    });

    it("should inject dependencies", async () => {
      expect(await dependant.token()).to.equal(ZERO_ADDR);

      await contractsRegistry.injectDependencies(await contractsRegistry.CRDEPENDANT_NAME());

      expect(await dependant.token()).to.equal(await token.getAddress());
    });

    it("should inject dependencies with data", async () => {
      expect(await dependant.token()).to.equal(ZERO_ADDR);

      await contractsRegistry.injectDependenciesWithData(await contractsRegistry.CRDEPENDANT_NAME(), "0x112233");

      expect(await dependant.token()).to.equal(await token.getAddress());
    });

    it("should not inject dependencies", async () => {
      await expect(contractsRegistry.injectDependencies("RANDOM CONTRACT")).to.be.revertedWith(
        "ContractsRegistry: this mapping doesn't exist"
      );
    });

    it("should not allow random users to inject dependencies", async () => {
      await contractsRegistry.injectDependencies(await contractsRegistry.CRDEPENDANT_NAME());

      expect(await dependant.getInjector()).to.equal(await contractsRegistry.getAddress());

      await expect(dependant.setDependencies(await contractsRegistry.getAddress(), "0x")).to.be.revertedWith(
        "Dependant: not an injector"
      );
    });

    it("should not allow random users to set new injector", async () => {
      await contractsRegistry.injectDependencies(await contractsRegistry.CRDEPENDANT_NAME());

      await expect(dependant.setInjector(OWNER)).to.be.revertedWith("Dependant: not an injector");
    });
  });
});
