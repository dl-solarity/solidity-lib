const truffleAssert = require("truffle-assertions");

const VectorMock = artifacts.require("VectorMock");

VectorMock.numberFormat = "BigNumber";

describe("Vector", () => {
  let vector;

  beforeEach("setup", async () => {
    vector = await VectorMock.new();
  });

  describe("raw vector", () => {
    it("should test new", async () => {
      await vector.testNew();
    });

    it("should test push and pop", async () => {
      await vector.testPushAndPop();
    });

    it("should test resize", async () => {
      await vector.testResize();
    });

    it("should test resize and set", async () => {
      await vector.testResizeAndSet();
    });

    it("should test empty vector", async () => {
      await truffleAssert.reverts(vector.testEmptyPop(), "Vector: empty vector");
      await truffleAssert.reverts(vector.testEmptySet(), "Vector: out of bounds");
      await truffleAssert.reverts(vector.testEmptyAt(), "Vector: out of bounds");
    });
  });

  describe("uint vector", () => {
    it("should test uint vector", async () => {
      await vector.testUintFunctionality();
    });
  });

  describe("bytes32 vector", () => {
    it("should test bytes32 vector", async () => {
      await vector.testBytes32Functionality();
    });
  });

  describe("address vector", () => {
    it("should test address vector", async () => {
      await vector.testAddressFunctionality();
    });
  });
});
