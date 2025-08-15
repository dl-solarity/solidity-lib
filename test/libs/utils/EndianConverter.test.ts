import { EndianConverterMock } from "@/generated-types/ethers";
import { reverseBytes } from "@/test/helpers/bytes-helpers";
import { Reverter } from "@/test/helpers/reverter";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("EndianConverter", () => {
  const reverter = new Reverter();

  let converter: EndianConverterMock;

  const bytes2 = "0x13d4";
  const bytes4 = "0xfa0513d4";
  const bytes8 = "0xfa000513fdd409ab";
  const bytes16 = "0x00100513fde409ababcdef1234567890";
  const bytes32 = "0x123456789abcdef000112233445566778899aabbccddeefffa000513fdd409ab";

  before(async () => {
    const EndianConverterMock = await ethers.getContractFactory("EndianConverterMock");
    converter = await EndianConverterMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  it("should correctly convert bytes", async () => {
    let expected = reverseBytes(bytes2);

    let output = await converter.bytes2BEtoLE(bytes2);

    expect(output).to.be.eq(expected);

    output = await converter.bytes2LEtoBE(bytes2);

    expect(output).to.be.eq(expected);

    expected = reverseBytes(bytes4);

    output = await converter.bytes4BEtoLE(bytes4);

    expect(output).to.be.eq(expected);

    output = await converter.bytes4LEtoBE(bytes4);

    expect(output).to.be.eq(expected);

    expected = reverseBytes(bytes8);

    output = await converter.bytes8BEtoLE(bytes8);

    expect(output).to.be.eq(expected);

    output = await converter.bytes8LEtoBE(bytes8);

    expect(output).to.be.eq(expected);

    expected = reverseBytes(bytes16);

    output = await converter.bytes16BEtoLE(bytes16);

    expect(output).to.be.eq(expected);

    output = await converter.bytes16LEtoBE(bytes16);

    expect(output).to.be.eq(expected);

    expected = reverseBytes(bytes32);

    output = await converter.bytes32BEtoLE(bytes32);

    expect(output).to.be.eq(expected);

    output = await converter.bytes32LEtoBE(bytes32);

    expect(output).to.be.eq(expected);
  });

  it("should correctly convert uints", async () => {
    const uint16 = BigInt(bytes2);
    const uint32 = BigInt(bytes4);
    const uint64 = BigInt(bytes8);
    const uint128 = BigInt(bytes16);
    const uint256 = BigInt(bytes32);

    let expected = BigInt(reverseBytes(bytes2));

    let output = await converter.uint16BEtoLE(uint16);

    expect(output).to.be.eq(expected);

    output = await converter.uint16LEtoBE(uint16);

    expect(output).to.be.eq(expected);

    expected = BigInt(reverseBytes(bytes4));

    output = await converter.uint32BEtoLE(uint32);

    expect(output).to.be.eq(expected);

    output = await converter.uint32LEtoBE(uint32);

    expect(output).to.be.eq(expected);

    expected = BigInt(reverseBytes(bytes8));

    output = await converter.uint64BEtoLE(uint64);

    expect(output).to.be.eq(expected);

    output = await converter.uint64LEtoBE(uint64);

    expect(output).to.be.eq(expected);

    expected = BigInt(reverseBytes(bytes16));

    output = await converter.uint128BEtoLE(uint128);

    expect(output).to.be.eq(expected);

    output = await converter.uint128LEtoBE(uint128);

    expect(output).to.be.eq(expected);

    expected = BigInt(reverseBytes(bytes32));

    output = await converter.uint256BEtoLE(uint256);

    expect(output).to.be.eq(expected);

    output = await converter.uint256LEtoBE(uint256);

    expect(output).to.be.eq(expected);
  });
});
