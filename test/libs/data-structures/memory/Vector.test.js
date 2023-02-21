const truffleAssert = require("truffle-assertions");

const VectorMock = artifacts.require("VectorMock");

VectorMock.numberFormat = "BigNumber";

describe("Vector", () => {
  let vector;

  beforeEach("setup", async () => {
    vector = await VectorMock.new();
  });

  it("should test init", async () => {
    await vector.testInit();
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
