const { assert } = require("chai");
const { accounts } = require("../../scripts/helpers/utils");
const truffleAssert = require("truffle-assertions");

const RBACMock = artifacts.require("RBACMock");

RBACMock.numberFormat = "BigNumber";

describe("RBAC", () => {
  let OWNER;
  let SECOND;

  let rbac;

  before("setup", async () => {
    OWNER = await accounts(0);
    SECOND = await accounts(1);
  });

  beforeEach("setup", async () => {
    rbac = await RBACMock.new();

    await rbac.__RBACMock_init();
  });

  describe("role permissions", () => {
    it("should add allowed permissions to role", async () => {
      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      assert.deepEqual(allowedPerms, []);

      await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], true);

      allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      assert.deepEqual(allowedPerms, ["permission1", "permission2"]);
    });

    it("should add disallowed permissions to role", async () => {
      let disAllowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disAllowedPerms, []);

      await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], false);

      disAllowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disAllowedPerms, ["permission1", "permission2"]);
    });

    it("should remove allowed permissions from role", async () => {
      await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], true);
      await rbac.removePermissionsFromRole("ROLE", ["permission1"], true);

      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      assert.deepEqual(allowedPerms, ["permission2"]);
    });

    it("should remove disallowed permissions from role", async () => {
      await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], false);
      await rbac.removePermissionsFromRole("ROLE", ["permission2"], false);

      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disallowedPerms, ["permission1"]);
    });
  });

  describe("user roles", () => {
    describe("allowed permissions", () => {
      it("should grant roles and check permissions (1)", async () => {
        await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "permission2"));
      });

      it("should grant roles and check permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", ["permission1"], true);
        await rbac.addPermissionsToRole("ROLE2", ["permission2"], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE1", "ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "permission1"));
        assert.isTrue(await rbac.hasPermission(SECOND, "permission2"));
      });

      it("should grant roles and check permissions (3)", async () => {
        await rbac.addPermissionsToRole("ROLE", [], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "permission"));

        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "permission"));
      });

      it("should add roles with proper permission", async () => {
        await rbac.addPermissionsToRole("RBAC_MASTER", ["RBAC.crud"], true);
        await rbac.grantRoles(SECOND, ["RBAC_MASTER"]);

        await truffleAssert.passes(rbac.grantRoles(OWNER, ["RBAC_MASTER"], { from: SECOND }), "pass");
      });

      it("should grant and revoke roles", async () => {
        await rbac.addPermissionsToRole("ROLE1", ["permission1"], true);
        await rbac.addPermissionsToRole("ROLE2", ["permission2"], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE1", "ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "permission1"));
        assert.isTrue(await rbac.hasPermission(SECOND, "permission2"));

        await rbac.revokeRoles(SECOND, ["ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "permission2"));
      });

      it("should check that MASTER has all permissions", async () => {
        await rbac.addPermissionsToRole("ROLE", ["permission"], true);

        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));

        await rbac.grantRoles(OWNER, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(OWNER), ["MASTER", "ROLE"]);
        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));
      });

      it("should revoke master role", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));

        await rbac.revokeRoles(OWNER, ["MASTER"]);

        assert.deepEqual(await rbac.getUserRoles(OWNER), []);
        assert.isFalse(await rbac.hasPermission(OWNER, "permission"));
      });
    });

    describe("disallowed permissions", async () => {
      it("should grant roles with disallowed permissions (1)", async () => {
        await rbac.addPermissionsToRole("ROLE", ["permission1", "permission2"], true);
        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.isTrue(await rbac.hasPermission(SECOND, "permission2"));

        await rbac.addPermissionsToRole("ROLE", ["permission2"], false);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "permission2"));
      });

      it("should grant roles with disallowed permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", ["permission1"], true);
        await rbac.grantRoles(SECOND, ["ROLE1"]);

        assert.isTrue(await rbac.hasPermission(SECOND, "permission1"));

        await rbac.addPermissionsToRole("ROLE2", ["permission1"], false);
        await rbac.grantRoles(SECOND, ["ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "permission1"));
      });

      it("should grant roles with disallowed permissions (3)", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));

        await rbac.addPermissionsToRole("MASTER", ["permission"], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "permission"));
      });

      it("should disallow all permissions", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));

        await rbac.addPermissionsToRole("MASTER", ["*"], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "permission"));
      });

      it("should revoke disallowing role", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));

        await rbac.addPermissionsToRole("ANTI_ROLE", ["permission"], false);
        await rbac.grantRoles(OWNER, ["ANTI_ROLE"]);

        assert.isFalse(await rbac.hasPermission(OWNER, "permission"));

        await rbac.revokeRoles(OWNER, ["ANTI_ROLE"]);

        assert.isTrue(await rbac.hasPermission(OWNER, "permission"));
      });
    });
  });

  describe("access", () => {
    it("should not call these functions without permission", async () => {
      await truffleAssert.reverts(rbac.grantRoles(OWNER, ["ROLE"], { from: SECOND }), "RBAC: no RBAC.crud permission");
      await truffleAssert.reverts(
        rbac.revokeRoles(OWNER, ["MASTER"], { from: SECOND }),
        "RBAC: no RBAC.crud permission"
      );
      await truffleAssert.reverts(
        rbac.addPermissionsToRole("ROLE", ["permission"], true, { from: SECOND }),
        "RBAC: no RBAC.crud permission"
      );
      await truffleAssert.reverts(
        rbac.removePermissionsFromRole("ROLE", ["permission"], false, { from: SECOND }),
        "RBAC: no RBAC.crud permission"
      );
    });
  });
});
