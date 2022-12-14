// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../data-structures/StringSet.sol";

library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    function add(EnumerableSet.AddressSet storage set, address[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.add(array[i]);
        }
    }

    function add(EnumerableSet.UintSet storage set, uint256[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.add(array[i]);
        }
    }

    function add(StringSet.Set storage set, string[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.add(array[i]);
        }
    }

    function remove(EnumerableSet.AddressSet storage set, address[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.remove(array[i]);
        }
    }

    function remove(EnumerableSet.UintSet storage set, uint256[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.remove(array[i]);
        }
    }

    function remove(StringSet.Set storage set, string[] memory array) internal {
        for (uint256 i = 0; i < array.length; i++) {
            set.remove(array[i]);
        }
    }
}
