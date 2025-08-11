// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EndianConverter} from "../../../libs/utils/EndianConverter.sol";

contract EndianConverterMock {
    using EndianConverter for *;

    function bytes2BEtoLE(bytes2 input_) external pure returns (bytes2) {
        return input_.bytes2BEtoLE();
    }

    function bytes4BEtoLE(bytes4 input_) external pure returns (bytes4) {
        return input_.bytes4BEtoLE();
    }

    function bytes8BEtoLE(bytes8 input_) external pure returns (bytes8) {
        return input_.bytes8BEtoLE();
    }

    function bytes16BEtoLE(bytes16 input_) external pure returns (bytes16) {
        return input_.bytes16BEtoLE();
    }

    function bytes32BEtoLE(bytes32 input_) external pure returns (bytes32) {
        return input_.bytes32BEtoLE();
    }

    function bytes2LEtoBE(bytes2 input_) external pure returns (bytes2) {
        return input_.bytes2LEtoBE();
    }

    function bytes4LEtoBE(bytes4 input_) external pure returns (bytes4) {
        return input_.bytes4LEtoBE();
    }

    function bytes8LEtoBE(bytes8 input_) external pure returns (bytes8) {
        return input_.bytes8LEtoBE();
    }

    function bytes16LEtoBE(bytes16 input_) external pure returns (bytes16) {
        return input_.bytes16LEtoBE();
    }

    function bytes32LEtoBE(bytes32 input_) external pure returns (bytes32) {
        return input_.bytes32LEtoBE();
    }

    function uint16BEtoLE(uint16 input_) external pure returns (uint16) {
        return input_.uint16BEtoLE();
    }

    function uint32BEtoLE(uint32 input_) external pure returns (uint32) {
        return input_.uint32BEtoLE();
    }

    function uint64BEtoLE(uint64 input_) external pure returns (uint64) {
        return input_.uint64BEtoLE();
    }

    function uint128BEtoLE(uint128 input_) external pure returns (uint128) {
        return input_.uint128BEtoLE();
    }

    function uint256BEtoLE(uint256 input_) external pure returns (uint256) {
        return input_.uint256BEtoLE();
    }

    function uint16LEtoBE(uint16 input_) external pure returns (uint16) {
        return input_.uint16LEtoBE();
    }

    function uint32LEtoBE(uint32 input_) external pure returns (uint32) {
        return input_.uint32LEtoBE();
    }

    function uint64LEtoBE(uint64 input_) external pure returns (uint64) {
        return input_.uint64LEtoBE();
    }

    function uint128LEtoBE(uint128 input_) external pure returns (uint128) {
        return input_.uint128LEtoBE();
    }

    function uint256LEtoBE(uint256 input_) external pure returns (uint256) {
        return input_.uint256LEtoBE();
    }
}
