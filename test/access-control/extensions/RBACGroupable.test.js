const { assert } = require("chai");
const { accounts } = require("../../../scripts/utils/utils");
const truffleAssert = require("truffle-assertions");

const RBACMock = artifacts.require("RBACGroupableMock");

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

    await rbac.__RBACGroupableMock_init();
  });

  describe("#__RBACGroupable_init", () => {
    it("should not initialize twice", async () => {
      await truffleAssert.reverts(rbac.mockInit(), "Initializable: contract is not initializing");
    });
  });

  context("if roles are created", () => {
    const roles = [
      {
        name: "role1",
        resourcesWithPermissions: [
          {
            resource: "resource1",
            permissions: ["permission1"],
          },
        ],
      },
      {
        name: "role2",
        resourcesWithPermissions: [
          {
            resource: "resource2",
            permissions: ["permission2"],
          },
        ],
      },
      {
        name: "role3",
        resourcesWithPermissions: [
          {
            resource: "resource3",
            permissions: ["permission3"],
          },
        ],
      },
    ];

    const GROUP_ALL_ROLES = "ALL_ROLES_GROUP";
    const GROUP_ROLES01 = "ROLES_0_1";
    const GROUP_ROLES12 = "ROLES_1_2";

    const ALL_ROLES = [roles[0].name, roles[1].name, roles[2].name];
    const ROLES_01 = [roles[0].name, roles[1].name];
    const ROLES_12 = [roles[1].name, roles[2].name];

    beforeEach(async () => {
      for (const role of roles) {
        await rbac.addPermissionsToRole(role.name, role.resourcesWithPermissions, true);
      }
    });

    describe("#grantGroupRoles", () => {
      it("should revert if no permission", async () => {
        await truffleAssert.reverts(
          rbac.grantGroupRoles(GROUP_ALL_ROLES, ALL_ROLES, { from: SECOND }),
          "RBAC: no CREATE permission for resource RBAC_RESOURCE"
        );
      });

      it("should revert if no roles provided", async () => {
        await truffleAssert.reverts(rbac.grantGroupRoles(GROUP_ALL_ROLES, []), "RBACGroupable: empty roles");
      });

      it("should grant group roles if all conditions are met", async () => {
        const tx = await rbac.grantGroupRoles(GROUP_ALL_ROLES, ALL_ROLES);

        truffleAssert.eventEmitted(tx.receipt, "GrantedGroupRoles");

        assert.deepEqual(await rbac.getGroupRoles(GROUP_ALL_ROLES), ALL_ROLES);
      });
    });

    context("if groups are created", () => {
      beforeEach(async () => {
        await rbac.grantGroupRoles(GROUP_ALL_ROLES, ALL_ROLES);
        await rbac.grantGroupRoles(GROUP_ROLES01, ROLES_01);
        await rbac.grantGroupRoles(GROUP_ROLES12, ROLES_12);
      });

      describe("#revokeGroupRoles", () => {
        it("should revert if no permission", async () => {
          await truffleAssert.reverts(
            rbac.revokeGroupRoles(GROUP_ALL_ROLES, ROLES_01, { from: SECOND }),
            "RBAC: no DELETE permission for resource RBAC_RESOURCE"
          );
        });

        it("should revert if no roles provided", async () => {
          await truffleAssert.reverts(rbac.revokeGroupRoles(GROUP_ALL_ROLES, []), "RBACGroupable: empty roles");
        });

        it("should revoke group roles if all conditions are met", async () => {
          const tx = await rbac.revokeGroupRoles(GROUP_ALL_ROLES, ROLES_01);

          truffleAssert.eventEmitted(tx.receipt, "RevokedGroupRoles");

          assert.deepEqual(await rbac.getGroupRoles(GROUP_ALL_ROLES), [roles[2].name]);
        });
      });

      describe("#addUserToGroups", () => {
        it("should revert if no permission", async () => {
          await truffleAssert.reverts(
            rbac.addUserToGroups(SECOND, [GROUP_ROLES01, GROUP_ROLES12], { from: SECOND }),
            "RBAC: no CREATE permission for resource RBAC_RESOURCE"
          );
        });

        it("should revert if no groups provided", async () => {
          await truffleAssert.reverts(rbac.addUserToGroups(SECOND, []), "RBACGroupable: empty groups");
        });

        it("should add the user to groups if all conditions are met", async () => {
          const tx = await rbac.addUserToGroups(SECOND, [GROUP_ROLES01, GROUP_ROLES12]);

          truffleAssert.eventEmitted(tx.receipt, "AddedToGroups");

          assert.deepEqual(await rbac.getUserGroups(SECOND), [GROUP_ROLES01, GROUP_ROLES12]);
        });
      });

      context("if the user is assigned to groups", () => {
        beforeEach(async () => {
          await rbac.addUserToGroups(SECOND, [GROUP_ROLES01, GROUP_ROLES12]);
        });

        describe("#removeUserFromGroups", () => {
          it("should revert if no permission", async () => {
            await truffleAssert.reverts(
              rbac.removeUserFromGroups(SECOND, [GROUP_ROLES01], { from: SECOND }),
              "RBAC: no DELETE permission for resource RBAC_RESOURCE"
            );
          });

          it("should revert if no groups provided", async () => {
            await truffleAssert.reverts(rbac.removeUserFromGroups(SECOND, []), "RBACGroupable: empty groups");
          });

          it("should remove the user from groups if all conditions are met", async () => {
            const tx = await rbac.removeUserFromGroups(SECOND, [GROUP_ROLES01]);

            truffleAssert.eventEmitted(tx.receipt, "RemovedFromGroups");

            assert.deepEqual(await rbac.getUserGroups(SECOND), [GROUP_ROLES12]);
          });
        });

        describe("#hasPermission", () => {
          it("should have the permission if only the group role", async () => {
            assert.isTrue(
              await rbac.hasPermission(
                SECOND,
                roles[0].resourcesWithPermissions[0].resource,
                roles[0].resourcesWithPermissions[0].permissions[0]
              )
            );
          });

          it("should have the permission if only own role", async () => {
            assert.isTrue(await rbac.hasPermission(OWNER, "*", "*"));
          });

          it("should not have the permission if the user has an antipermission", async () => {
            const BANNED_ZERO_ROLE = "BANNED_ZERO_ROLE";

            await rbac.addPermissionsToRole(BANNED_ZERO_ROLE, roles[0].resourcesWithPermissions, false);
            await rbac.grantRoles(SECOND, [BANNED_ZERO_ROLE]);

            assert.isFalse(
              await rbac.hasPermission(
                SECOND,
                roles[0].resourcesWithPermissions[0].resource,
                roles[0].resourcesWithPermissions[0].permissions[0]
              )
            );
          });

          it("should not have the permission if the group has an antipermission", async () => {
            const BANNED_ZERO_ROLE = "BANNED_ZERO_ROLE";

            await rbac.addPermissionsToRole(BANNED_ZERO_ROLE, roles[0].resourcesWithPermissions, false);
            await rbac.grantGroupRoles(GROUP_ROLES12, [BANNED_ZERO_ROLE]);

            assert.isFalse(
              await rbac.hasPermission(
                SECOND,
                roles[0].resourcesWithPermissions[0].resource,
                roles[0].resourcesWithPermissions[0].permissions[0]
              )
            );
          });

          it("should not have the permission if it is not assigned", async () => {
            assert.isFalse(await rbac.hasPermission(SECOND, "*", "*"));
          });
        });
      });
    });
  });
});
