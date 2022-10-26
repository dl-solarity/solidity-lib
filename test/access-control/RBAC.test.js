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

      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true
      );

      allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      assert.deepEqual(allowedPerms, [["resource", ["permission1", "permission2"]]]);
    });

    it("should add disallowed permissions to role", async () => {
      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disallowedPerms, []);

      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false
      );

      disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disallowedPerms, [["resource", ["permission1", "permission2"]]]);
    });

    it("should remove allowed permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true
      );
      await rbac.removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission1"] }], true);

      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];

      assert.deepEqual(allowedPerms, [["resource", ["permission2"]]]);
    });

    it("should remove disallowed permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false
      );
      await rbac.removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission2"] }], false);

      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(disallowedPerms, [["resource", ["permission1"]]]);
    });

    it("should remove all permissions from role", async () => {
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true
      );
      await rbac.addPermissionsToRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false
      );

      await rbac.removePermissionsFromRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        true
      );
      await rbac.removePermissionsFromRole(
        "ROLE",
        [{ resource: "resource", permissions: ["permission1", "permission2"] }],
        false
      );

      let allowedPerms = (await rbac.getRolePermissions("ROLE"))[0];
      let disallowedPerms = (await rbac.getRolePermissions("ROLE"))[1];

      assert.deepEqual(allowedPerms, []);
      assert.deepEqual(disallowedPerms, []);
    });
  });

  describe("user roles", () => {
    describe("allowed permissions", () => {
      it("should grant roles and check permissions (1)", async () => {
        await rbac.addPermissionsToRole(
          "ROLE",
          [{ resource: "resource", permissions: ["permission1", "permission2"] }],
          true
        );

        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission2"));
      });

      it("should grant roles and check permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource1", permissions: ["permission1"] }], true);
        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource2", permissions: ["permission2"] }], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "resource1", "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "resource2", "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE1", "ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "resource1", "permission1"));
        assert.isTrue(await rbac.hasPermission(SECOND, "resource2", "permission2"));
      });

      it("should grant roles and check permissions (3)", async () => {
        await rbac.addPermissionsToRole("ROLE", [], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));

        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));
      });

      it("should grant roles and check permissions (4)", async () => {
        await rbac.addPermissionsToRole("ROLE", [{ resource: "resource", permissions: [] }], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));

        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));
      });

      it("should add roles with proper permission", async () => {
        await rbac.addPermissionsToRole("RBAC_MASTER", [{ resource: "RBAC_RESOURCE", permissions: ["CREATE"] }], true);
        await rbac.grantRoles(SECOND, ["RBAC_MASTER"]);

        await truffleAssert.passes(rbac.grantRoles(OWNER, ["RBAC_MASTER"], { from: SECOND }), "pass");
      });

      it("should grant and revoke roles", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource", permissions: ["permission1"] }], true);
        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission2"] }], true);

        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission2"));

        await rbac.grantRoles(SECOND, ["ROLE1", "ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission1"));
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission2"));

        await rbac.revokeRoles(SECOND, ["ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1"]);
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission1"));
        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission2"));
      });

      it("should check that MASTER has all permissions", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));
        assert.isTrue(await rbac.hasPermission(OWNER, "", ""));
      });

      it("should revoke master role", async () => {
        await rbac.revokeRoles(OWNER, ["MASTER"]);

        assert.deepEqual(await rbac.getUserRoles(OWNER), []);
        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));
        assert.isFalse(await rbac.hasPermission(OWNER, "", ""));
      });
    });

    describe("disallowed permissions", async () => {
      it("should grant roles with disallowed permissions (1)", async () => {
        await rbac.addPermissionsToRole(
          "ROLE",
          [{ resource: "resource", permissions: ["permission1", "permission2"] }],
          true
        );
        await rbac.grantRoles(SECOND, ["ROLE"]);

        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission2"));
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission1"));

        await rbac.addPermissionsToRole("ROLE", [{ resource: "resource", permissions: ["permission2"] }], false);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE"]);

        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission2"));
        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission1"));
      });

      it("should grant roles with disallowed permissions (2)", async () => {
        await rbac.addPermissionsToRole("ROLE1", [{ resource: "resource", permissions: ["permission"] }], true);
        await rbac.grantRoles(SECOND, ["ROLE1"]);

        assert.isTrue(await rbac.hasPermission(SECOND, "resource", "permission"));

        await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission"] }], false);
        await rbac.grantRoles(SECOND, ["ROLE2"]);

        assert.deepEqual(await rbac.getUserRoles(SECOND), ["ROLE1", "ROLE2"]);
        assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));
      });

      it("should disallow specific permission", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.addPermissionsToRole("MASTER", [{ resource: "resource", permissions: ["permission"] }], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));
      });

      it("should disallow resource", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.addPermissionsToRole("MASTER", [{ resource: "resource", permissions: ["*"] }], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));
        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission2"));
      });

      it("should disallow specific permission on all resources", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.addPermissionsToRole("MASTER", [{ resource: "*", permissions: ["permission"] }], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));
        assert.isFalse(await rbac.hasPermission(OWNER, "resource2", "permission"));
      });

      it("should disallow all permissions", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.addPermissionsToRole("MASTER", [{ resource: "*", permissions: ["*"] }], false);

        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));
        assert.isFalse(await rbac.hasPermission(OWNER, "resource2", "permission2"));
      });

      it("should revoke disallowing role", async () => {
        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.addPermissionsToRole("ANTI_ROLE", [{ resource: "resource", permissions: ["permission"] }], false);
        await rbac.grantRoles(OWNER, ["ANTI_ROLE"]);

        assert.isFalse(await rbac.hasPermission(OWNER, "resource", "permission"));

        await rbac.revokeRoles(OWNER, ["ANTI_ROLE"]);

        assert.isTrue(await rbac.hasPermission(OWNER, "resource", "permission"));
      });
    });
  });

  describe("extreme roles", () => {
    it("should work correctly", async () => {
      await rbac.addPermissionsToRole("ROLE1", [{ resource: "*", permissions: ["permission"] }], true);
      await rbac.addPermissionsToRole("ROLE2", [{ resource: "resource", permissions: ["permission"] }], false);

      await rbac.grantRoles(SECOND, ["ROLE1", "ROLE2"]);

      assert.isFalse(await rbac.hasPermission(SECOND, "resource", "permission"));
    });
  });

  describe("access", () => {
    it("should not call these functions without permission", async () => {
      await truffleAssert.reverts(
        rbac.grantRoles(OWNER, ["ROLE"], { from: SECOND }),
        "RBAC: no CREATE permission for resource RBAC"
      );
      await truffleAssert.reverts(
        rbac.revokeRoles(OWNER, ["MASTER"], { from: SECOND }),
        "RBAC: no DELETE permission for resource RBAC"
      );
      await truffleAssert.reverts(
        rbac.addPermissionsToRole("ROLE", [{ resource: "resource", permissions: ["permission"] }], true, {
          from: SECOND,
        }),
        "RBAC: no CREATE permission for resource RBAC"
      );
      await truffleAssert.reverts(
        rbac.removePermissionsFromRole("ROLE", [{ resource: "resource", permissions: ["permission"] }], false, {
          from: SECOND,
        }),
        "RBAC: no DELETE permission for resource RBAC"
      );
    });
  });
});
