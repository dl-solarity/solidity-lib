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
        _set(self, key_.asSingletonArray(), value_);
    }

    function set(Storage storage self, string[] memory key_, bytes memory value_) internal {
        _set(self, key_, value_);
    }

    function remove(Storage storage self, string memory key_) internal {
        _remove(self, key_.asSingletonArray());
    }

    function remove(Storage storage self, string[] memory key_) internal {
        _remove(self, key_);
    }

    function get(Storage storage self, string memory key_) internal view returns (bytes memory) {
        return _dive(self, key_.asSingletonArray())._value;
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

    function _set(Storage storage self, string[] memory key_, bytes memory value_) private {
        require(value_.length > 0, "RecursiveStorage: empty value");

        _dive(self, key_)._value = value_;
    }

    function _remove(Storage storage self, string[] memory key_) private {
        Storage storage _storage = _dive(self, key_);

        require(_storage._value.length > 0, "RecursiveStorage: value does not exist");

        _storage._value = bytes("");
    }
}
