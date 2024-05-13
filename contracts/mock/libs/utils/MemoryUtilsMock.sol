// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../../../libs/utils/MemoryUtils.sol";
import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

contract MemoryUtilsMock {
    using TypeCaster for *;
    using MemoryUtils for *;

    function testBytesMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length);

        require(
            keccak256(data_) != keccak256(someBytes_),
            "MemoryUtilsMock: testBytesMemoryCopy failed. Initial data and someBytes are equal"
        );

        someBytes_ = data_.copy();

        require(
            keccak256(data_) == keccak256(someBytes_),
            "MemoryUtilsMock: testBytesMemoryCopy failed. Initial data and someBytes are not equal"
        );
    }

    function testBytes32MemoryCopy(bytes32[] memory data_) external view {
        bytes32[] memory someBytes_ = new bytes32[](data_.length);

        require(
            keccak256(abi.encode(data_)) != keccak256(abi.encode(someBytes_)),
            "MemoryUtilsMock: testBytes32MemoryCopy failed. Initial data and someBytes are equal"
        );

        someBytes_ = data_.copy();

        require(
            keccak256(abi.encode(data_)) == keccak256(abi.encode(someBytes_)),
            "MemoryUtilsMock: testBytes32MemoryCopy failed. Initial data and someBytes are not equal"
        );
    }

    function testUnsafeMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length);

        require(
            keccak256(data_) != keccak256(someBytes_),
            "MemoryUtilsMock: testBigMemory failed. Initial data and someBytes are equal"
        );

        MemoryUtils.unsafeCopy(
            MemoryUtils.getDataPointer(someBytes_),
            MemoryUtils.getDataPointer(data_),
            someBytes_.length
        );

        require(
            keccak256(data_) == keccak256(someBytes_),
            "MemoryUtilsMock: testBigMemory failed. Initial data and someBytes are not equal"
        );
    }

    function testPartialCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length / 2);

        require(
            keccak256(data_) != keccak256(someBytes_),
            "MemoryUtilsMock: testPartialCopy failed. Initial data and someBytes are equal"
        );

        MemoryUtils.unsafeCopy(
            MemoryUtils.getDataPointer(someBytes_),
            MemoryUtils.getDataPointer(data_),
            someBytes_.length
        );

        for (uint256 i = 0; i < someBytes_.length; i++) {
            require(
                someBytes_[i] == data_[i],
                "MemoryUtilsMock: testPartialCopy failed. Initial data and someBytes are not equal"
            );
        }
    }

    /**
     * @dev Since the underlying logic of `getPointer()/getDataPointer()` is only specific to EVMs,
     * we only do a simple mock test for coverage.
     */
    function testForCoverage() external pure {
        MemoryUtils.getPointer(new bytes(1));
        MemoryUtils.getPointer((new uint256[](1)).asBytes32Array());

        MemoryUtils.getDataPointer(new bytes(1));
        MemoryUtils.getDataPointer((new uint256[](1)).asBytes32Array());
    }
}
