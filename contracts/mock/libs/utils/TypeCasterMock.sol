// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

contract TypeCasterMock {
    using TypeCaster for *;

    function asUint256ArrayFromBytes32Array(
        bytes32[] memory from_
    ) external pure returns (uint256[] memory) {
        return from_.asUint256Array();
    }

    function asUint256ArrayFromAddressArray(
        address[] memory from_
    ) external pure returns (uint256[] memory) {
        return from_.asUint256Array();
    }

    function asAddressArrayFromBytes32Array(
        bytes32[] memory from_
    ) external pure returns (address[] memory) {
        return from_.asAddressArray();
    }

    function asAddressArrayFromUint256Array(
        uint256[] memory from_
    ) external pure returns (address[] memory) {
        return from_.asAddressArray();
    }

    function asBytes32ArrayFromUint256Array(
        uint256[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asBytes32ArrayFromAddressArray(
        address[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asSingletonArrayFromUint256(uint256 from_) external pure returns (uint256[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromAddress(address from_) external pure returns (address[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromString(
        string memory from_
    ) external pure returns (string[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromBytes32(bytes32 from_) external pure returns (bytes32[] memory) {
        return from_.asSingletonArray();
    }
}
