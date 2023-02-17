// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./TypeCaster.sol";

library RecursiveStorageUtils {
    using TypeCaster for *;

    struct RecursiveStorage {
        bytes _value;
        mapping(string => RecursiveStorage) _values;
    }

    function set(
        RecursiveStorage storage recursiveStorage,
        string memory key_,
        bytes memory value_
    ) internal {
        require(value_.length > 0, "RecursiveStorageUtils: empty value");

        _dive(recursiveStorage, key_.asArray())._value = value_;
    }

    function set(
        RecursiveStorage storage recursiveStorage,
        string[] memory key_,
        bytes memory value_
    ) internal {
        require(value_.length > 0, "RecursiveStorageUtils: empty value");

        _dive(recursiveStorage, key_)._value = value_;
    }

    function remove(RecursiveStorage storage recursiveStorage, string memory key_) internal {
        RecursiveStorage storage _recursiveStorage = _dive(recursiveStorage, key_.asArray());

        require(
            _recursiveStorage._value.length > 0,
            "RecursiveStorageUtils: value does not exist"
        );

        _recursiveStorage._value = bytes("");
    }

    function remove(RecursiveStorage storage recursiveStorage, string[] memory key_) internal {
        RecursiveStorage storage _recursiveStorage = _dive(recursiveStorage, key_);

        require(
            _recursiveStorage._value.length > 0,
            "RecursiveStorageUtils: value does not exist"
        );

        _recursiveStorage._value = bytes("");
    }

    function get(
        RecursiveStorage storage recursiveStorage,
        string memory key_
    ) internal view returns (bytes memory) {
        return _dive(recursiveStorage, key_.asArray())._value;
    }

    function get(
        RecursiveStorage storage recursiveStorage,
        string[] memory key_
    ) internal view returns (bytes memory) {
        return _dive(recursiveStorage, key_)._value;
    }

    function _dive(
        RecursiveStorage storage recursiveStorage,
        string[] memory key_
    ) private view returns (RecursiveStorage storage) {
        RecursiveStorage storage _recursiveStorage = recursiveStorage;

        for (uint256 i = 0; i < key_.length; i++) {
            _recursiveStorage = _recursiveStorage._values[key_[i]];
        }

        return _recursiveStorage;
    }
}
