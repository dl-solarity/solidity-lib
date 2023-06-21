const { assert } = require("chai");
const { accounts } = require("../../scripts/utils/utils");

const truffleAssert = require("truffle-assertions");

const MultiOwnable = artifacts.require("MultiOwnableMock");

describe("MultiOwnable", () => {
  let FIRST;
  let SECOND;
  let THIRD;

  let crk;

  before("setup", async () => {
    FIRST = await accounts(0);
    SECOND = await accounts(1);
    THIRD = await accounts(2);
  });

  beforeEach("setup", async () => {
    crk = await MultiOwnable.new();

    await crk.__MultiOwnable_init();
  });
  
  describe("access", () => {    
    it("should not initialize twice", async () => {    
      await truffleAssert.reverts(
        crk.mockInit(), "Initializable: contract is not initializing");     
      await truffleAssert.reverts(
        crk.__MultiOwnable_init(), "Initializable: contract is already initialized");
    });    
    
    it("only owner should call these functions", async () => {         
      await truffleAssert.reverts(
        crk.addOwners([THIRD], { from: SECOND }), "AbstractMultiOwnable: caller is not the owner"); 
    
      await crk.addOwners([THIRD]);     
      await truffleAssert.reverts(
        crk.removeOwners([THIRD], { from: SECOND }), "AbstractMultiOwnable: caller is not the owner");   
          
      await truffleAssert.reverts(
        crk.renounceOwnership({ from: SECOND }), "AbstractMultiOwnable: caller is not the owner");
    });
  });

  describe("addOwners()", () => {  
    it("should correctly add owners", async () => {
      await crk.addOwners([SECOND, THIRD]);
      assert.equal((await crk.isOwner(SECOND)), true);
      assert.equal((await crk.isOwner(THIRD)), true);
    });

    it("should not add null address", async () => {         
      await truffleAssert.reverts(
        crk.addOwners(["0x0000000000000000000000000000000000000000"]), "AbstractMultiOwnable: zero address can not be added");
    });

  });

  describe("removeOwners()", () => {
    it("should correctly remove the owner", async () => { 
      await crk.addOwners([SECOND]);
      await crk.removeOwners([SECOND, THIRD]);

      assert.equal((await crk.isOwner(SECOND)), false);
      assert.equal((await crk.isOwner(FIRST)), true);
    });    
    
    it("should not remove all owners", async () => {    
      await crk.addOwners([SECOND]);     
      await truffleAssert.reverts(
        crk.removeOwners([FIRST, SECOND]), "AbstractMultiOwnable: no owners left after removal");
    });
  });

  describe("renounceOwnership()", () => {
    it("should correctly remove the owner", async () => {  
      await crk.addOwners([THIRD]);    
      assert.equal((await crk.isOwner(THIRD)), true);

      await crk.renounceOwnership({ from: THIRD });
      assert.equal((await crk.isOwner(THIRD)), false);
    });    

    it("should not renounce last owner", async () => {         
      await truffleAssert.reverts(
        crk.renounceOwnership(), "AbstractMultiOwnable: no owners left after removal");
    });
  }); 
  
  describe("getOwners()", () => {
    it("should correctly set the owner after inizialization", async () => {      
      assert.equal((await crk.getOwners()), FIRST);
    });
  });

  describe("isOwner()", () => {
    it("should correctly check the initial owner", async () => {      
      assert.equal((await crk.isOwner(FIRST)), true);
    });    

    it("should return false for not owner", async () => {          
      assert.equal((await crk.isOwner(SECOND)), false);
    });
  });
});