// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library BytesCaster {
    function toBytes(bool arg) internal pure returns (bytes memory) {
        return abi.encode(arg);
    }

    function toBytes(address arg) internal pure returns (bytes memory) {
        return abi.encode(arg);
    }

    function toBytes(uint256 arg) internal pure returns (bytes memory) {
        return abi.encode(arg);
    }

    function toBytes(bytes32 arg) internal pure returns (bytes memory) {
        return abi.encode(arg);
    }

    function toBytes(string memory arg) internal pure returns (bytes memory) {
        return abi.encode(arg);
    }

    function asBool(bytes memory arg) internal pure returns (bool) {
        return abi.decode(arg, (bool));
    }

    function asAddress(bytes memory arg) internal pure returns (address) {
        return abi.decode(arg, (address));
    }

    function asBytes32(bytes memory arg) internal pure returns (bytes32) {
        return abi.decode(arg, (bytes32));
    }

    function asUint256(bytes memory arg) internal pure returns (uint256) {
        return abi.decode(arg, (uint256));
    }

    function asString(bytes memory arg) internal pure returns (string memory) {
        return abi.decode(arg, (string));
    }
}
