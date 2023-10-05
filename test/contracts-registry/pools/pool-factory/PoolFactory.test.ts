import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ZERO_ADDR } from "@/scripts/utils/constants";

import {
  PoolFactory,
  PublicBeaconProxy,
  PoolContractsRegistry,
  ContractsRegistry2,
  Pool,
  PoolUpgrade,
  ERC20Mock,
} from "@ethers-v6";

describe("PoolFactory", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let poolFactory: PoolFactory;
  let poolContractsRegistry: PoolContractsRegistry;
  let contractsRegistry: ContractsRegistry2;
  let token: ERC20Mock;

  let NAME_1: string;
  let NAME_2: string;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    const ContractsRegistry2 = await ethers.getContractFactory("ContractsRegistry2");
    const PoolFactory = await ethers.getContractFactory("PoolFactory");
    const PoolContractsRegistry = await ethers.getContractFactory("PoolContractsRegistry");
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    contractsRegistry = await ContractsRegistry2.deploy();
    const _poolFactory = await PoolFactory.deploy();
    const _poolContractsRegistry = await PoolContractsRegistry.deploy();
    token = await ERC20Mock.deploy("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      await _poolContractsRegistry.getAddress()
    );
    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_FACTORY_NAME(),
      await _poolFactory.getAddress()
    );
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), await token.getAddress());

    poolContractsRegistry = <PoolContractsRegistry>(
      await PoolContractsRegistry.attach(await contractsRegistry.getPoolContractsRegistryContract())
    );
    poolFactory = <PoolFactory>await PoolFactory.attach(await contractsRegistry.getPoolFactoryContract());

    await poolContractsRegistry.__OwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());
    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_FACTORY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should not set dependencies from non dependant", async () => {
      await expect(poolFactory.setDependencies(OWNER, "0x")).to.be.revertedWith("Dependant: not an injector");
    });
  });

  describe("after setting the implementation", () => {
    let poolImpl: Pool;

    beforeEach("setup", async () => {
      const Pool = await ethers.getContractFactory("Pool");
      poolImpl = await Pool.deploy();

      await poolContractsRegistry.setNewImplementations([NAME_1], [await poolImpl.getAddress()]);
    });

    describe("deploy()", () => {
      it("should deploy pool", async () => {
        await poolFactory.deployPool();

        expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(1n);
        expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);

        const Pool = await ethers.getContractFactory("Pool");
        const PublicBeaconProxy = await ethers.getContractFactory("PublicBeaconProxy");

        const pool = <Pool>await Pool.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);
        const beaconProxy = <PublicBeaconProxy>await PublicBeaconProxy.attach(await pool.getAddress());

        expect(await beaconProxy.implementation()).to.equal(await poolImpl.getAddress());
        expect(await pool.token()).not.to.equal(ZERO_ADDR);
      });

      it("should not register pools", async () => {
        await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);
        await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

        await expect(poolFactory.deployPool()).to.be.revertedWith("AbstractPoolFactory: failed to register contract");
      });

      it("should deploy several pools", async () => {
        await poolFactory.deployPool();
        await poolFactory.deployPool();
        await poolFactory.deployPool();

        expect(await poolContractsRegistry.countPools(NAME_1)).to.be.equal(3n);
      });

      it("should set access correctly", async () => {
        await poolFactory.deployPool();

        const Pool = await ethers.getContractFactory("Pool");
        const pool = <Pool>await Pool.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);

        await expect(poolContractsRegistry.addProxyPool(NAME_1, await poolFactory.getAddress())).to.be.revertedWith(
          "PoolContractsRegistry: not a factory"
        );
        await expect(pool.setDependencies(await contractsRegistry.getAddress(), "0x")).to.be.revertedWith(
          "Dependant: not an injector"
        );
      });

      it("should upgrade pools", async () => {
        await poolFactory.deployPool();

        const PoolUpgrade = await ethers.getContractFactory("PoolUpgrade");
        const pool1 = <PoolUpgrade>await PoolUpgrade.attach((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);

        await expect(pool1.addedFunction()).to.be.reverted;

        const poolUpgrade = await PoolUpgrade.deploy();
        await poolContractsRegistry.setNewImplementations([NAME_1], [await poolUpgrade.getAddress()]);

        expect(await pool1.addedFunction()).to.equal(42n);

        await poolFactory.deployPool();

        const pool2 = <PoolUpgrade>await PoolUpgrade.attach((await poolContractsRegistry.listPools(NAME_1, 1, 1))[0]);
        expect(await pool2.addedFunction()).to.equal(42n);
      });
    });

    describe("deploy2() predictPoolAddress()", () => {
      const SALT1 = "pool_salt1";
      const SALT2 = "pool_salt2";

      it("should deploy to the predicted address", async () => {
        const predictedAddress1 = await poolFactory.predictPoolAddress(SALT1);
        const predictedAddress2 = await poolFactory.predictPoolAddress(SALT2);

        await poolFactory.deploy2Pool(SALT1);
        await poolFactory.deploy2Pool(SALT2);

        expect(await poolContractsRegistry.countPools(NAME_1)).to.equal(2n);
        expect(await poolContractsRegistry.countPools(NAME_2)).to.equal(0n);

        const pools = await poolContractsRegistry.listPools(NAME_1, 0, 2);

        expect(pools).to.equal([predictedAddress1, predictedAddress2]);

        const Pool = await ethers.getContractFactory("Pool");
        const PublicBeaconProxy = await ethers.getContractFactory("PublicBeaconProxy");

        const poolProxies = await Promise.all(pools.map(async (pool) => <Pool>await Pool.attach(pool)));
        const beaconProxies = await Promise.all(
          pools.map(async (pool) => <PublicBeaconProxy>await PublicBeaconProxy.attach(pool))
        );

        const tokens = await Promise.all(poolProxies.map(async (poolProxy) => await poolProxy.token()));
        const implementations = await Promise.all(
          beaconProxies.map(async (beaconProxy) => await beaconProxy.implementation())
        );

        expect(tokens).to.equal([await token.getAddress(), await token.getAddress()]);
        expect(implementations).to.equal([await poolImpl.getAddress(), await poolImpl.getAddress()]);
      });

      it("should revert when deploying the pool with the same salt", async () => {
        await poolFactory.deploy2Pool(SALT1);

        await expect(poolFactory.deploy2Pool(SALT1)).to.be.revertedWith("VM Exception while processing transaction");
      });
    });
  });
});
