// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/utils/TypeCaster.sol";

contract TypeCasterMock {
    using TypeCaster for *;

    function asBytes_Bool(bool from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBytes_Address(address from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBytes_Uint256(uint256 from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBytes_Bytes32(bytes32 from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBytes_String(string memory from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBytes_Bytes32Array(bytes32[] memory from_) external pure returns (bytes memory) {
        return from_.asBytes();
    }

    function asBool_Bytes(bytes memory from_) external pure returns (bool) {
        return from_.asBool();
    }

    function asAddress_Bytes(bytes memory from_) external pure returns (address) {
        return from_.asAddress();
    }

    function asBytes32_Bytes(bytes memory from_) external pure returns (bytes32) {
        return from_.asBytes32();
    }

    function asUint256_Bytes(bytes memory from_) external pure returns (uint256) {
        return from_.asUint256();
    }

    function asString_Bytes(bytes memory from_) external pure returns (string memory) {
        return from_.asString();
    }

    function asBytes32Array_Bytes(bytes memory from_) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asUint256Array_Bytes32Array(
        bytes32[] memory from_
    ) external pure returns (uint256[] memory) {
        return from_.asUint256Array();
    }

    function asAddressArray_Bytes32Array(
        bytes32[] memory from_
    ) external pure returns (address[] memory) {
        return from_.asAddressArray();
    }

    function asBytes32Array_Uint256Array(
        uint256[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asBytes32Array_AddressArray(
        address[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asSingletonArray_Uint256(uint256 from_) external pure returns (uint256[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArray_Address(address from_) external pure returns (address[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArray_String(string memory from_) external pure returns (string[] memory) {
        return from_.asSingletonArray();
    }
}
