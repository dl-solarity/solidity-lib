// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../../libs/data-structures/StringSet.sol";
import "../../../libs/arrays/SetHelper.sol";

contract SetHelperMock {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;
    using SetHelper for EnumerableSet.UintSet;
    using SetHelper for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal addressSet;
    EnumerableSet.UintSet internal uintSet;
    StringSet.Set internal stringSet;

    function addToAddressSet(address[] memory arr) external {
        addressSet.add(arr);
    }

    function addToUintSet(uint256[] memory arr) external {
        uintSet.add(arr);
    }

    function addToStringSet(string[] memory arr) external {
        stringSet.add(arr);
    }

    function removeFromAddressSet(address[] memory arr) external {
        addressSet.remove(arr);
    }

    function removeFromUintSet(uint256[] memory arr) external {
        uintSet.remove(arr);
    }

    function removeFromStringSet(string[] memory arr) external {
        stringSet.remove(arr);
    }

    function getAddressSet() external view returns (address[] memory) {
        return addressSet.values();
    }

    function getUintSet() external view returns (uint256[] memory) {
        return uintSet.values();
    }

    function getStringSet() external view returns (string[] memory) {
        return stringSet.values();
    }
}
