// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TypeCaster {
    function asBytes(bool from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBytes(address from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBytes(uint256 from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBytes(bytes32 from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBytes(string memory from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBytes(bytes32[] memory from) internal pure returns (bytes memory) {
        return abi.encode(from);
    }

    function asBool(bytes memory from) internal pure returns (bool) {
        return abi.decode(from, (bool));
    }

    function asAddress(bytes memory from) internal pure returns (address) {
        return abi.decode(from, (address));
    }

    function asBytes32(bytes memory from) internal pure returns (bytes32) {
        return abi.decode(from, (bytes32));
    }

    function asUint256(bytes memory from) internal pure returns (uint256) {
        return abi.decode(from, (uint256));
    }

    function asString(bytes memory from) internal pure returns (string memory) {
        return abi.decode(from, (string));
    }

    function asBytes32Array(bytes memory from) internal pure returns (bytes32[] memory) {
        return abi.decode(from, (bytes32[]));
    }

    function asUint256Array(
        bytes32[] memory from
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asAddressArray(
        bytes32[] memory from
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asBytes32Array(
        uint256[] memory from
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asBytes32Array(
        address[] memory from
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asSingletonArray(uint256 from) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from;
    }

    function asSingletonArray(address from) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from;
    }

    function asSingletonArray(string memory from) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from;
    }
}
