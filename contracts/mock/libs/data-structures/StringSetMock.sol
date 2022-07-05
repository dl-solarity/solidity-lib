// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libs/data-structures/StringSet.sol";

contract StringSetMock {
    using StringSet for StringSet.Set;

    StringSet.Set internal _set;

    function add(string memory value) external {
        _set.add(value);
    }

    function remove(string memory value) external {
        _set.remove(value);
    }

    function contains(string memory value) external view returns (bool) {
        return _set.contains(value);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) external view returns (string memory) {
        return _set.at(index);
    }

    function getSet() external view returns (string[] memory set) {
        set = new string[](_set.length());
        for (uint256 i = 0; i < _set.length(); i++) {
            set[i] = _set.at(i);
        }
    }
}
