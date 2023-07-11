// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArrayConverter} from "../../../libs/arrays/ArrayConverter.sol";

contract ArrayConverterMock {
    using ArrayConverter for *;

    function testLength(uint256[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function testLength(address[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function testLength(bool[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function testLength(string[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function testLength(bytes32[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function testUint() external pure returns (bool) {
        return
            (1 == testLength([uint256(1)].toDynamic())) &&
            (2 == testLength([uint256(1), 2].toDynamic())) &&
            (3 == testLength([uint256(2), 3, 2].toDynamic())) &&
            (4 == testLength([uint256(2), 4, 3, 2].toDynamic())) &&
            (5 == testLength([uint256(2), 3, 2, 1, 5].toDynamic())) &&
            (6 == testLength([uint256(2), 3, 2, 1, 5, 6].toDynamic())) &&
            (7 == testLength([uint256(2), 3, 2, 1, 5, 6, 7].toDynamic())) &&
            (8 == testLength([uint256(2), 3, 2, 1, 5, 6, 7, 8].toDynamic())) &&
            (9 == testLength([uint256(2), 3, 2, 1, 5, 6, 7, 8, 9].toDynamic())) &&
            (10 == testLength([uint256(2), 3, 2, 1, 5, 6, 7, 8, 9, 10].toDynamic()));
    }

    function testAddress() external pure returns (bool) {
        return
            (1 == testLength([address(0)].toDynamic())) &&
            (2 == testLength([address(0), address(1)].toDynamic())) &&
            (3 == testLength([address(0), address(1), address(0)].toDynamic())) &&
            (4 == testLength([address(0), address(1), address(0), address(1)].toDynamic())) &&
            (5 ==
                testLength(
                    [address(0), address(1), address(0), address(1), address(0)].toDynamic()
                )) &&
            (6 ==
                testLength(
                    [address(0), address(1), address(0), address(1), address(0), address(1)]
                        .toDynamic()
                )) &&
            (7 ==
                testLength(
                    [
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0)
                    ].toDynamic()
                )) &&
            (8 ==
                testLength(
                    [
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1)
                    ].toDynamic()
                )) &&
            (9 ==
                testLength(
                    [
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0)
                    ].toDynamic()
                )) &&
            (10 ==
                testLength(
                    [
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1),
                        address(0),
                        address(1)
                    ].toDynamic()
                ));
    }

    function testBool() external pure returns (bool) {
        return
            (1 == testLength([true].toDynamic())) &&
            (2 == testLength([true, true].toDynamic())) &&
            (3 == testLength([true, true, true].toDynamic())) &&
            (4 == testLength([true, true, true, true].toDynamic())) &&
            (5 == testLength([true, true, true, true, true].toDynamic())) &&
            (6 == testLength([true, true, true, true, true, true].toDynamic())) &&
            (7 == testLength([true, true, true, true, true, true, true].toDynamic())) &&
            (8 == testLength([true, true, true, true, true, true, true, true].toDynamic())) &&
            (9 ==
                testLength([true, true, true, true, true, true, true, true, true].toDynamic())) &&
            (10 ==
                testLength(
                    [true, true, true, true, true, true, true, true, true, true].toDynamic()
                ));
    }

    function testString() external pure returns (bool) {
        return
            (1 == testLength([""].toDynamic())) &&
            (2 == testLength(["", ""].toDynamic())) &&
            (3 == testLength(["", "", ""].toDynamic())) &&
            (4 == testLength(["", "", "", ""].toDynamic())) &&
            (5 == testLength(["", "", "", "", ""].toDynamic())) &&
            (6 == testLength(["", "", "", "", "", ""].toDynamic())) &&
            (7 == testLength(["", "", "", "", "", "", ""].toDynamic())) &&
            (8 == testLength(["", "", "", "", "", "", "", ""].toDynamic())) &&
            (9 == testLength(["", "", "", "", "", "", "", "", ""].toDynamic())) &&
            (10 == testLength(["", "", "", "", "", "", "", "", "", ""].toDynamic()));
    }

    function testBytes32() external pure returns (bool) {
        return
            (1 == testLength([bytes32(0)].toDynamic())) &&
            (2 == testLength([bytes32(0), bytes32(0)].toDynamic())) &&
            (3 == testLength([bytes32(0), bytes32(0), bytes32(0)].toDynamic())) &&
            (4 == testLength([bytes32(0), bytes32(0), bytes32(0), bytes32(0)].toDynamic())) &&
            (5 ==
                testLength(
                    [bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)].toDynamic()
                )) &&
            (6 ==
                testLength(
                    [bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)]
                        .toDynamic()
                )) &&
            (7 ==
                testLength(
                    [
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0)
                    ].toDynamic()
                )) &&
            (8 ==
                testLength(
                    [
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0)
                    ].toDynamic()
                )) &&
            (9 ==
                testLength(
                    [
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0)
                    ].toDynamic()
                )) &&
            (10 ==
                testLength(
                    [
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0),
                        bytes32(0)
                    ].toDynamic()
                ));
    }
}
