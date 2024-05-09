// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../../../libs/utils/MemoryUtils.sol";

contract MemoryUtilsMock {
    using MemoryUtils for *;

    function testStringMemoryCopy(string memory data_) external view {
        string memory someString = new string(data_.getSize());

        require(
            keccak256(bytes(data_)) != keccak256(bytes(someString)),
            "MemoryUtilsMock: testStringMemoryCopy failed. Initial data and someString are equal"
        );

        data_.copyTo(someString);

        require(
            keccak256(bytes(data_)) == keccak256(bytes(someString)),
            "MemoryUtilsMock: testStringMemoryCopy failed. Initial data and someString are not equal"
        );
    }

    function testBytesMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes = new bytes(data_.length);

        require(
            keccak256(data_) != keccak256(someBytes),
            "MemoryUtilsMock: testBytesMemoryCopy failed. Initial data and someBytes are equal"
        );

        data_.copyTo(someBytes);

        require(
            keccak256(data_) == keccak256(someBytes),
            "MemoryUtilsMock: testBytesMemoryCopy failed. Initial data and someBytes are not equal"
        );
    }

    function testUnsafeMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes = new bytes(data_.length);

        require(
            keccak256(data_) != keccak256(someBytes),
            "MemoryUtilsMock: testBigMemory failed. Initial data and someBytes are equal"
        );

        MemoryUtils.unsafeMemoryCopy(
            MemoryUtils.getPointer(someBytes),
            MemoryUtils.getPointer(data_),
            someBytes.length
        );

        require(
            keccak256(data_) == keccak256(someBytes),
            "MemoryUtilsMock: testBigMemory failed. Initial data and someBytes are not equal"
        );
    }

    function testPartialCopy(bytes memory data_) external view {
        bytes memory someBytes = new bytes(data_.length / 2);

        require(
            keccak256(data_) != keccak256(someBytes),
            "MemoryUtilsMock: testPartialCopy failed. Initial data and someBytes are equal"
        );

        MemoryUtils.unsafeMemoryCopy(
            MemoryUtils.getPointer(someBytes),
            MemoryUtils.getPointer(data_),
            someBytes.length
        );

        for (uint256 i = 0; i < someBytes.length; i++) {
            require(
                someBytes[i] == data_[i],
                "MemoryUtilsMock: testPartialCopy failed. Initial data and someBytes are not equal"
            );
        }
    }

    function testStringMemoryCopyRevert(string memory data_) external view {
        data_.copyTo(new string(data_.getSize() - 1));
    }

    function testBytesMemoryCopyRevert(bytes memory data_) external view {
        data_.copyTo(new bytes(data_.length - 1));
    }
}
