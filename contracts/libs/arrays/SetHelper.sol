// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice A simple library to work with Openzeppelin sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     * @notice The function to insert an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the uint256 set
     */
    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the string set
     */
    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function strictAdd(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the uint256 set
     */
    function strictAdd(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the string set
     */
    function strictAdd(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.add(array_[i]), "SetHelper: element already exists");
        }
    }

    /**
     * @notice The function to remove an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the uint256 set
     */
    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the string set
     */
    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function strictRemove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the uint256 set
     */
    function strictRemove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the string set
     */
    function strictRemove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            require(set.remove(array_[i]), "SetHelper: no such element");
        }
    }
}
