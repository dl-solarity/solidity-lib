// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../data-structures/StringSet.sol";

/**
 *  @notice Library for pagination.
 *
 *  Supports the following data types `uin256[]`, `address[]`, `bytes32[]`, `UintSet`,
 * `AddressSet`, `BytesSet`, `StringSet`.
 *
 */
library Paginator {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using StringSet for StringSet.Set;

    /**
     * @notice Returns part of an array.
     * @dev All functions below have the same description.
     *
     * Examples:
     * - part([4, 5, 6, 7], 0, 4) will return [4, 5, 6, 7]
     * - part([4, 5, 6, 7], 2, 4) will return [6, 7]
     * - part([4, 5, 6, 7], 2, 1) will return [6]
     *
     * @param arr Storage array.
     * @param offset Offset, index in an array.
     * @param limit Number of elements after the `offset`.
     */
    function part(
        uint256[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (uint256[] memory list) {
        uint256 to = _handleIncomingParametersForPart(arr.length, offset, limit);

        list = new uint256[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = arr[i];
        }
    }

    function part(
        address[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (address[] memory list) {
        uint256 to = _handleIncomingParametersForPart(arr.length, offset, limit);

        list = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = arr[i];
        }
    }

    function part(
        bytes32[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (bytes32[] memory list) {
        uint256 to = _handleIncomingParametersForPart(arr.length, offset, limit);

        list = new bytes32[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = arr[i];
        }
    }

    function part(
        EnumerableSet.UintSet storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (uint256[] memory list) {
        uint256 to = _handleIncomingParametersForPart(set.length(), offset, limit);

        list = new uint256[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = set.at(i);
        }
    }

    function part(
        EnumerableSet.AddressSet storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (address[] memory list) {
        uint256 to = _handleIncomingParametersForPart(set.length(), offset, limit);

        list = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = set.at(i);
        }
    }

    function part(
        EnumerableSet.Bytes32Set storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (bytes32[] memory list) {
        uint256 to = _handleIncomingParametersForPart(set.length(), offset, limit);

        list = new bytes32[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = set.at(i);
        }
    }

    function part(
        StringSet.Set storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (string[] memory list) {
        uint256 to = _handleIncomingParametersForPart(set.length(), offset, limit);

        list = new string[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            list[i - offset] = set.at(i);
        }
    }

    function _handleIncomingParametersForPart(
        uint256 length,
        uint256 offset,
        uint256 limit
    ) private pure returns (uint256 to) {
        to = offset + limit;

        if (to > length) to = length;
        if (offset > to) to = offset;
    }
}
