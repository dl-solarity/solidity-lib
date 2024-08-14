// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../../../libs/utils/MemoryUtils.sol";
import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

contract MemoryUtilsMock {
    using TypeCaster for *;
    using MemoryUtils for *;

    error BytesMemoryCopyInitialDataAndSomeBytesAreInvalid(bool ifEqual);
    error Bytes32MemoryCopyInitialDataAndSomeBytesAreInvalid(bool ifEqual);
    error BigMemoryInitialDataAndSomeBytesAreInvalid(bool ifEqual);
    error PartialCopyInitialDataAndSomeBytesAreInvalid(bool ifEqual);

    function testBytesMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length);

        if (keccak256(data_) == keccak256(someBytes_)) {
            revert BytesMemoryCopyInitialDataAndSomeBytesAreInvalid(true);
        }

        someBytes_ = data_.copy();

        if (keccak256(data_) != keccak256(someBytes_)) {
            revert BytesMemoryCopyInitialDataAndSomeBytesAreInvalid(false);
        }
    }

    function testBytes32MemoryCopy(bytes32[] memory data_) external view {
        bytes32[] memory someBytes_ = new bytes32[](data_.length);

        if (keccak256(abi.encode(data_)) == keccak256(abi.encode(someBytes_))) {
            revert Bytes32MemoryCopyInitialDataAndSomeBytesAreInvalid(true);
        }

        someBytes_ = data_.copy();

        if (keccak256(abi.encode(data_)) != keccak256(abi.encode(someBytes_))) {
            revert Bytes32MemoryCopyInitialDataAndSomeBytesAreInvalid(false);
        }
    }

    function testUnsafeMemoryCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length);

        if (keccak256(data_) == keccak256(someBytes_)) {
            revert BigMemoryInitialDataAndSomeBytesAreInvalid(true);
        }

        MemoryUtils.unsafeCopy(
            MemoryUtils.getDataPointer(someBytes_),
            MemoryUtils.getDataPointer(data_),
            someBytes_.length
        );

        if (keccak256(data_) != keccak256(someBytes_)) {
            revert BigMemoryInitialDataAndSomeBytesAreInvalid(false);
        }
    }

    function testPartialCopy(bytes memory data_) external view {
        bytes memory someBytes_ = new bytes(data_.length / 2);

        if (keccak256(data_) == keccak256(someBytes_)) {
            revert PartialCopyInitialDataAndSomeBytesAreInvalid(true);
        }

        MemoryUtils.unsafeCopy(
            MemoryUtils.getDataPointer(someBytes_),
            MemoryUtils.getDataPointer(data_),
            someBytes_.length
        );

        for (uint256 i = 0; i < someBytes_.length; i++) {
            if (someBytes_[i] != data_[i]) {
                revert PartialCopyInitialDataAndSomeBytesAreInvalid(false);
            }
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
