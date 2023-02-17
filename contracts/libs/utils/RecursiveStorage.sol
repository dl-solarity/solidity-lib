// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TypeCaster.sol";

library RecursiveStorage {
    using TypeCaster for *;

    struct Storage {
        bytes _value;
        mapping(string => Storage) _values;
    }

    function set(Storage storage self, string memory key_, bytes memory value_) internal {
        require(value_.length > 0, "RecursiveStorage: empty value");

        _dive(self, key_.asArray())._value = value_;
    }

    function set(Storage storage self, string[] memory key_, bytes memory value_) internal {
        require(value_.length > 0, "RecursiveStorage: empty value");

        _dive(self, key_)._value = value_;
    }

    function remove(Storage storage self, string memory key_) internal {
        Storage storage _storage = _dive(self, key_.asArray());

        require(_storage._value.length > 0, "RecursiveStorage: value does not exist");

        _storage._value = bytes("");
    }

    function remove(Storage storage self, string[] memory key_) internal {
        Storage storage _storage = _dive(self, key_);

        require(_storage._value.length > 0, "RecursiveStorage: value does not exist");

        _storage._value = bytes("");
    }

    function get(Storage storage self, string memory key_) internal view returns (bytes memory) {
        return _dive(self, key_.asArray())._value;
    }

    function get(Storage storage self, string[] memory key_) internal view returns (bytes memory) {
        return _dive(self, key_)._value;
    }

    function _dive(
        Storage storage self,
        string[] memory key_
    ) private view returns (Storage storage) {
        Storage storage _storage = self;

        for (uint256 i = 0; i < key_.length; i++) {
            _storage = _storage._values[key_[i]];
        }

        return _storage;
    }
}
