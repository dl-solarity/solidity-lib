import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import { PoolContractsRegistry, ContractsRegistry2, Pool, PoolUpgrade, ERC20Mock } from "@ethers-v6";

describe("PoolContractsRegistry", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let SECOND: SignerWithAddress;

  let poolContractsRegistry: PoolContractsRegistry;
  let contractsRegistry: ContractsRegistry2;
  let token: ERC20Mock;

  let POOL_1: SignerWithAddress;
  let POOL_2: SignerWithAddress;

  let NAME_1: string;
  let NAME_2: string;

  before("setup", async () => {
    [OWNER, SECOND, , POOL_1, POOL_2] = await ethers.getSigners();

    const ContractsRegistry2 = await ethers.getContractFactory("ContractsRegistry2");
    const PoolContractsRegistry = await ethers.getContractFactory("PoolContractsRegistry");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    contractsRegistry = await ContractsRegistry2.deploy();
    const _poolContractsRegistry = await PoolContractsRegistry.deploy();
    token = await ERC20Mock.deploy("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      await _poolContractsRegistry.getAddress()
    );
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());
    await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);

    poolContractsRegistry = <PoolContractsRegistry>(
      PoolContractsRegistry.attach(await contractsRegistry.getPoolContractsRegistryContract())
    );

    await poolContractsRegistry.__OwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not initialize twice", async () => {
      await expect(poolContractsRegistry.__OwnablePoolContractsRegistry_init()).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );

      await expect(poolContractsRegistry.mockInit()).to.be.revertedWith("Initializable: contract is not initializing");
    });

    it("should not set dependencies from non dependant", async () => {
      await expect(poolContractsRegistry.setDependencies(OWNER.address, "0x")).to.be.rejectedWith(
        "Dependant: not an injector"
      );
    });

    it("only owner should call these functions", async () => {
      await expect(poolContractsRegistry.connect(SECOND).setNewImplementations([], [])).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await expect(
        poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPools("", 0, 0)
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await expect(
        poolContractsRegistry.connect(SECOND).injectDependenciesToExistingPoolsWithData("", "0x", 0, 0)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("setNewImplementations()", () => {
    it("should successfully add and get implementation", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [await token.getAddress()]);

      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await token.getAddress());
      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).not.to.equal(ZERO_ADDR);
    });

    it("should not get not existing implementation", async () => {
      await expect(poolContractsRegistry.getImplementation(NAME_1)).to.be.revertedWith(
        "PoolContractsRegistry: this mapping doesn't exist"
      );
      await expect(poolContractsRegistry.getProxyBeacon(NAME_1)).to.be.revertedWith(
        "PoolContractsRegistry: bad ProxyBeacon"
      );
    });
  });

  describe("addProxyPool()", () => {
    it("should add pool", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1.address);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2.address);

      expect(await poolContractsRegistry.isPool(NAME_1, POOL_1.address)).to.be.true;
      expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(2n);
      expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);
    });

    it("should list added pools", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1.address);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2.address);

      expect(await poolContractsRegistry.listPools(NAME_1, 0, 2)).to.deep.equal([POOL_1.address, POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 0, 10)).to.deep.equal([POOL_1.address, POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 1, 1)).to.deep.equal([POOL_2.address]);
      expect(await poolContractsRegistry.listPools(NAME_1, 2, 0)).to.deep.equal([]);
      expect(await poolContractsRegistry.listPools(NAME_2, 0, 2)).to.deep.equal([]);
    });

    it("only owner should be able to add pools", async () => {
      await expect(poolContractsRegistry.connect(POOL_1).addProxyPool(NAME_1, POOL_1.address)).to.be.revertedWith(
        "PoolContractsRegistry: not a factory"
      );
    });
  });

  describe("injectDependenciesToExistingPools()", () => {
    let pool: Pool;

    beforeEach("setup", async () => {
      const Pool = await ethers.getContractFactory("Pool");
      pool = await Pool.deploy();
    });

    it("should inject dependencies", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, await pool.getAddress());

      expect(await pool.token()).to.equal(ZERO_ADDR);

      await poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1);

      expect(await pool.token()).to.equal(await token.getAddress());
    });

    it("should inject dependencies with data", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, await pool.getAddress());

      expect(await pool.token()).to.equal(ZERO_ADDR);

      await poolContractsRegistry.injectDependenciesToExistingPoolsWithData(NAME_1, "0x", 0, 1);

      expect(await pool.token()).to.equal(await token.getAddress());
    });

    it("should not inject dependencies to 0 pools", async () => {
      await expect(poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1)).to.be.revertedWith(
        "PoolContractsRegistry: no pools to inject"
      );
    });
  });

  describe("upgrade pools", () => {
    let pool: Pool;
    let poolUpgrade: PoolUpgrade;

    beforeEach("setup", async () => {
      const Pool = await ethers.getContractFactory("Pool");
      const PoolUpgrade = await ethers.getContractFactory("PoolUpgrade");

      pool = await Pool.deploy();
      poolUpgrade = await PoolUpgrade.deploy();
    });

    it("should upgrade pools", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [await pool.getAddress()]);

      const beacon = await poolContractsRegistry.getProxyBeacon(NAME_1);

      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await pool.getAddress());

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).to.equal(beacon);
      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await poolUpgrade.getAddress());

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

      expect(await poolContractsRegistry.getProxyBeacon(NAME_1)).to.equal(beacon);
      expect(await poolContractsRegistry.getImplementation(NAME_1)).to.equal(await poolUpgrade.getAddress());
    });
  });
});
