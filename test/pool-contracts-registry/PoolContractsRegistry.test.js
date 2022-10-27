const { assert } = require("chai");
const { accounts } = require("../../scripts/helpers/utils");
const truffleAssert = require("truffle-assertions");

const PoolContractsRegistry = artifacts.require("PoolContractsRegistry");
const ContractsRegistry = artifacts.require("ContractsRegistry2");
const Pool = artifacts.require("Pool");
const PoolUpgrade = artifacts.require("PoolUpgrade");
const ERC20Mock = artifacts.require("ERC20Mock");

PoolContractsRegistry.numberFormat = "BigNumber";
ContractsRegistry.numberFormat = "BigNumber";
Pool.numberFormat = "BigNumber";
PoolUpgrade.numberFormat = "BigNumber";
ERC20Mock.numberFormat = "BigNumber";

describe("PoolContractsRegistry", () => {
  let ZERO = "0x0000000000000000000000000000000000000000";
  let OWNER;
  let SECOND;

  let poolContractsRegistry;
  let contractsRegistry;
  let token;

  let POOL_1;
  let POOL_2;

  let NAME_1;
  let NAME_2;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);

    POOL_1 = await accounts(3);
    POOL_2 = await accounts(4);
  });

  beforeEach("setup", async () => {
    contractsRegistry = await ContractsRegistry.new();
    const _poolContractsRegistry = await PoolContractsRegistry.new();
    token = await ERC20Mock.new("Mock", "Mock", 18);

    await contractsRegistry.__OwnableContractsRegistry_init();

    await contractsRegistry.addProxyContract(
      await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME(),
      _poolContractsRegistry.address
    );
    await contractsRegistry.addContract(await contractsRegistry.TOKEN_NAME(), token.address);
    await contractsRegistry.addContract(await contractsRegistry.POOL_FACTORY_NAME(), OWNER);

    poolContractsRegistry = await PoolContractsRegistry.at(await contractsRegistry.getPoolContractsRegistryContract());

    await poolContractsRegistry.__OwnablePoolContractsRegistry_init();

    await contractsRegistry.injectDependencies(await contractsRegistry.POOL_CONTRACTS_REGISTRY_NAME());

    NAME_1 = await poolContractsRegistry.POOL_1_NAME();
    NAME_2 = await poolContractsRegistry.POOL_2_NAME();
  });

  describe("access", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(
        poolContractsRegistry.__OwnablePoolContractsRegistry_init(),
        "Initializable: contract is already initialized"
      );

      await truffleAssert.reverts(poolContractsRegistry.mockInit(), "Initializable: contract is not initializing");
    });

    it("should not set dependencies from non dependant", async () => {
      await truffleAssert.reverts(poolContractsRegistry.setDependencies(OWNER), "Dependant: Not an injector");
    });

    it("only owner should call these functions", async () => {
      await truffleAssert.reverts(
        poolContractsRegistry.setNewImplementations([], [], { from: SECOND }),
        "Ownable: caller is not the owner"
      );

      await truffleAssert.reverts(
        poolContractsRegistry.injectDependenciesToExistingPools("", 0, 0, { from: SECOND }),
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("setNewImplementations()", () => {
    it("should successfully add and get implementation", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [token.address]);

      assert.equal(await poolContractsRegistry.getImplementation(NAME_1), token.address);
      assert.notEqual(await poolContractsRegistry.getProxyBeacon(NAME_1), ZERO);
    });

    it("should not get not existing implementation", async () => {
      await truffleAssert.reverts(
        poolContractsRegistry.getImplementation(NAME_1),
        "PoolContractsRegistry: This mapping doesn't exist"
      );
      await truffleAssert.reverts(
        poolContractsRegistry.getProxyBeacon(NAME_1),
        "PoolContractsRegistry: Bad ProxyBeacon"
      );
    });
  });

  describe("addProxyPool()", () => {
    it("should add pool", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2);

      assert.equal((await poolContractsRegistry.countPools(NAME_1)).toFixed(), "2");
      assert.equal((await poolContractsRegistry.countPools(NAME_2)).toFixed(), "0");
    });

    it("should list added pools", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_1);
      await poolContractsRegistry.addProxyPool(NAME_1, POOL_2);

      assert.deepEqual(await poolContractsRegistry.listPools(NAME_1, 0, 2), [POOL_1, POOL_2]);
      assert.deepEqual(await poolContractsRegistry.listPools(NAME_1, 0, 10), [POOL_1, POOL_2]);
      assert.deepEqual(await poolContractsRegistry.listPools(NAME_1, 1, 1), [POOL_2]);
      assert.deepEqual(await poolContractsRegistry.listPools(NAME_1, 2, 0), []);
      assert.deepEqual(await poolContractsRegistry.listPools(NAME_2, 0, 2), []);
    });

    it("only owner should be able to add pools", async () => {
      await truffleAssert.reverts(
        poolContractsRegistry.addProxyPool(NAME_1, POOL_1, { from: POOL_1 }),
        "PoolContractsRegistry: not a factory"
      );
    });
  });

  describe("injectDependenciesToExistingPools()", () => {
    let pool;

    beforeEach("setup", async () => {
      pool = await Pool.new();
    });

    it("should inject dependencies", async () => {
      await poolContractsRegistry.addProxyPool(NAME_1, pool.address);

      assert.equal(await pool.token(), ZERO);

      await poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1);

      assert.equal(await pool.token(), token.address);
    });

    it("should not inject dependencies to 0 pools", async () => {
      await truffleAssert.reverts(
        poolContractsRegistry.injectDependenciesToExistingPools(NAME_1, 0, 1),
        "PoolContractsRegistry: No pools to inject"
      );
    });
  });

  describe("upgrade pools", () => {
    let pool;
    let poolUpgrade;

    beforeEach("setup", async () => {
      pool = await Pool.new();
      poolUpgrade = await PoolUpgrade.new();
    });

    it("should upgrade pools", async () => {
      await poolContractsRegistry.setNewImplementations([NAME_1], [pool.address]);

      const beacon = await poolContractsRegistry.getProxyBeacon(NAME_1);

      assert.equal(await poolContractsRegistry.getImplementation(NAME_1), pool.address);

      await poolContractsRegistry.setNewImplementations([NAME_1], [poolUpgrade.address]);

      assert.equal(await poolContractsRegistry.getProxyBeacon(NAME_1), beacon);
      assert.equal(await poolContractsRegistry.getImplementation(NAME_1), poolUpgrade.address);

      await poolContractsRegistry.setNewImplementations([NAME_1], [poolUpgrade.address]);

      assert.equal(await poolContractsRegistry.getProxyBeacon(NAME_1), beacon);
      assert.equal(await poolContractsRegistry.getImplementation(NAME_1), poolUpgrade.address);
    });
  });
});
