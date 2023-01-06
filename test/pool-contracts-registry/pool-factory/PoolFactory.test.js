const { assert } = require("chai");
const { toBN, accounts } = require("../../../scripts/utils/utils");
const { ZERO_ADDR } = require("../../../scripts/utils/constants");
const truffleAssert = require("truffle-assertions");

const PoolFactory = artifacts.require("PoolFactory");
const BeaconProxy = artifacts.require("PublicBeaconProxy");
const PoolContractsRegistry = artifacts.require("PoolContractsRegistry");
const ContractsRegistry = artifacts.require("ContractsRegistry2");
const Pool = artifacts.require("Pool");
const PoolUpgrade = artifacts.require("PoolUpgrade");
const ERC20Mock = artifacts.require("ERC20Mock");

PoolFactory.numberFormat = "BigNumber";
PoolContractsRegistry.numberFormat = "BigNumber";
ContractsRegistry.numberFormat = "BigNumber";
Pool.numberFormat = "BigNumber";
PoolUpgrade.numberFormat = "BigNumber";
ERC20Mock.numberFormat = "BigNumber";

describe("PoolFactory", () => {
  let OWNER;

  let poolFactory;
  let poolContractsRegistry;
  let contractsRegistry;
  let token;

  let NAME_1;
  let NAME_2;

  before("setup", async () => {
    OWNER = await accounts(0);
  });

  beforeEach("setup", async () => {
    contractsRegistry = await ContractsRegistry.new();
    const _poolFactory = await PoolFactory.new();
    const _poolContractsRegistry = await PoolContractsRegistry.new();
    token = await ERC20Mock.new("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      _poolContractsRegistry.address
    );
    await contractsRegistry.addProxyContract(await contractsRegistry.POOL_FACTORY_NAME(), _poolFactory.address);
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), token.address);

    poolContractsRegistry = await PoolContractsRegistry.at(await contractsRegistry.getPoolContractsRegistryContract());
    poolFactory = await PoolFactory.at(await contractsRegistry.getPoolFactoryContract());

    await poolContractsRegistry.__OwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());
    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_FACTORY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();
  });

  describe("access", () => {
    it("should not set dependencies from non dependant", async () => {
      await truffleAssert.reverts(poolFactory.setDependencies(OWNER), "Dependant: Not an injector");
    });
  });

  describe("after setting the implementation", () => {
    let poolImpl;

    beforeEach("setup", async () => {
      poolImpl = await Pool.new();

      await poolContractsRegistry.setNewImplementations([NAME_1], [poolImpl.address]);
    });

    describe("deploy()", () => {
      it("should deploy pool", async () => {
        await poolFactory.deployPool();

        assert.equal(toBN(await poolContractsRegistry.countPools(NAME_1)).toFixed(), "1");
        assert.equal(toBN(await poolContractsRegistry.countPools(NAME_2)).toFixed(), "0");

        const pool = await Pool.at((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);
        const beaconProxy = await BeaconProxy.at(pool.address);

        assert.equal(await beaconProxy.implementation(), poolImpl.address);
        assert.notEqual(await pool.token(), ZERO_ADDR);
      });

      it("should not register pools", async () => {
        await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);
        await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

        await truffleAssert.reverts(poolFactory.deployPool(), "AbstractPoolFactory: failed to register contract");
      });

      it("should deploy several pools", async () => {
        await poolFactory.deployPool();
        await poolFactory.deployPool();
        await poolFactory.deployPool();
        assert.equal(toBN(await poolContractsRegistry.countPools(NAME_1)).toFixed(), "3");
      });

      it("should set access correctly", async () => {
        await poolFactory.deployPool();

        const pool = await Pool.at((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);

        await truffleAssert.reverts(
          poolContractsRegistry.addProxyPool(NAME_1, poolFactory.address),
          "PoolContractsRegistry: not a factory"
        );
        await truffleAssert.reverts(pool.setDependencies(contractsRegistry.address), "Dependant: Not an injector");
      });

      it("should upgrade pools", async () => {
        await poolFactory.deployPool();

        const pool1 = await PoolUpgrade.at((await poolContractsRegistry.listPools(NAME_1, 0, 1))[0]);
        await truffleAssert.reverts(pool1.addedFunction());

        const poolUpgrade = await PoolUpgrade.new();
        await poolContractsRegistry.setNewImplementations([NAME_1], [poolUpgrade.address]);

        assert.equal(toBN(await pool1.addedFunction()).toFixed(), "42");

        await poolFactory.deployPool();

        const pool2 = await PoolUpgrade.at((await poolContractsRegistry.listPools(NAME_1, 1, 1))[0]);
        assert.equal(toBN(await pool2.addedFunction()).toFixed(), "42");
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

        assert.equal(toBN(await poolContractsRegistry.countPools(NAME_1)).toFixed(), "2");
        assert.equal(toBN(await poolContractsRegistry.countPools(NAME_2)).toFixed(), "0");

        const pools = await poolContractsRegistry.listPools(NAME_1, 0, 2);

        assert.deepEqual(pools, [predictedAddress1, predictedAddress2]);

        const poolProxies = await Promise.all(pools.map(async (pool) => await Pool.at(pool)));
        const beaconProxies = await Promise.all(pools.map(async (pool) => await BeaconProxy.at(pool)));

        const tokens = await Promise.all(poolProxies.map(async (poolProxy) => await poolProxy.token()));
        const implementations = await Promise.all(
          beaconProxies.map(async (beaconProxy) => await beaconProxy.implementation())
        );

        assert.deepEqual(tokens, [token.address, token.address]);
        assert.deepEqual(implementations, [poolImpl.address, poolImpl.address]);
      });

      it("should revert when deploying the pool with the same salt", async () => {
        await poolFactory.deploy2Pool(SALT1);
        await truffleAssert.reverts(poolFactory.deploy2Pool(SALT1), "VM Exception while processing transaction");
      });
    });
  });
});
