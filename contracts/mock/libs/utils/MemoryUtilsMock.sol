// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MemoryUtils} from "../../../libs/utils/MemoryUtils.sol";

contract MemoryUtilsMock {
    using MemoryUtils for *;

    function testSmallMemoryCopy() external pure {
        bytes32 someBytes32_ = 0x0102460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a020;

        uint256 offset_ = _saveBytes32InMemory(someBytes32_);

        MemoryUtils.copyMemory(offset_ + 1024, offset_, 64);

        bytes memory actual_ = _getMemory(offset_);
        bytes memory expected_ = _getMemory(offset_ + 1024);

        require(
            keccak256(actual_) == keccak256(expected_),
            "MemoryUtilsMock: testSmallMemory failed"
        );
    }

    function testBigMemoryCopy() external pure {
        bytes32 part1Bytes32_ = 0x0102460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a020;
        bytes32 part2Bytes32_ = 0x0112460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a021;

        uint256 offset_ = _saveBytesInMemory(part1Bytes32_, part2Bytes32_);

        MemoryUtils.copyMemory(offset_ + 1024, offset_, 96);

        bytes memory actual_ = _getMemory(offset_);
        bytes memory expected_ = _getMemory(offset_ + 1024);

        require(
            keccak256(actual_) == keccak256(expected_),
            "MemoryUtilsMock: testBigMemory failed"
        );
    }

    function copyMemory(uint256 destinationOffset_, uint256 offset_, uint256 size_) external pure {
        MemoryUtils.copyMemory(destinationOffset_, offset_, size_);
    }

    function _saveBytes32InMemory(bytes32 value_) internal pure returns (uint256 offset_) {
        assembly {
            offset_ := mload(64)
            mstore(offset_, 32)
            mstore(add(offset_, 32), value_)

            mstore(64, add(offset_, 64))
        }
    }

    function _saveBytesInMemory(
        bytes32 value1_,
        bytes32 value2_
    ) internal pure returns (uint256 offset_) {
        assembly {
            offset_ := mload(64)
            mstore(offset_, 64)

            mstore(64, add(offset_, 96))
            mstore(add(offset_, 32), value1_)
            mstore(add(offset_, 64), value2_)
        }
    }

    function _getMemory(uint256 offset_) internal pure returns (bytes memory result_) {
        assembly {
            let size_ := mload(offset_)

            result_ := mload(64)
            mstore(result_, size_)

            mstore(64, add(result_, add(size_, 32)))

            for {
                let i := 0
            } lt(i, size_) {
                i := add(i, 32)
            } {
                mstore(add(result_, add(i, 32)), mload(add(offset_, i)))
            }
        }
    }
}
