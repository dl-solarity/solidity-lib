// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/utils/TypeCaster.sol";

contract TypeCasterMock {
    using TypeCaster for *;

    function boolToBytes(bool arg) external pure returns (bytes memory) {
        return arg.toBytes();
    }

    function addressToBytes(address arg) external pure returns (bytes memory) {
        return arg.toBytes();
    }

    function uint256ToBytes(uint256 arg) external pure returns (bytes memory) {
        return arg.toBytes();
    }

    function bytes32ToBytes(bytes32 arg) external pure returns (bytes memory) {
        return arg.toBytes();
    }

    function stringToBytes(string memory arg) external pure returns (bytes memory) {
        return arg.toBytes();
    }

    function asBool(bytes memory arg) external pure returns (bool) {
        return arg.asBool();
    }

    function asAddress(bytes memory arg) external pure returns (address) {
        return arg.asAddress();
    }

    function asBytes32(bytes memory arg) external pure returns (bytes32) {
        return arg.asBytes32();
    }

    function asUint256(bytes memory arg) external pure returns (uint256) {
        return arg.asUint256();
    }

    function asString(bytes memory arg) external pure returns (string memory) {
        return arg.asString();
    }

    function asArrayUint256(uint256 elem) external pure returns (uint256[] memory) {
        return elem.asArray();
    }

    function asArrayAddress(address elem) external pure returns (address[] memory) {
        return elem.asArray();
    }

    function asArrayString(string memory elem) external pure returns (string[] memory) {
        return elem.asArray();
    }
}
