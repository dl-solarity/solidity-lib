// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StringSet} from "../../../libs/data-structures/StringSet.sol";

contract StringSetMock {
    using StringSet for StringSet.Set;

    StringSet.Set internal _set;

    function add(string calldata value_) external {
        _set.add(value_);
    }

    function remove(string calldata value_) external {
        _set.remove(value_);
    }

    function contains(string calldata value_) external view returns (bool) {
        return _set.contains(value_);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index_) external view returns (string memory) {
        return _set.at(index_);
    }

    function values() external view returns (string[] memory) {
        return _set.values();
    }

    function getSet() external view returns (string[] memory set_) {
        set_ = new string[](_set.length());

        for (uint256 i = 0; i < set_.length; i++) {
            set_[i] = _set.at(i);
        }
    }
}
