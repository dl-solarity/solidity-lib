// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DynamicSet {
    struct Set {
        bytes[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes memory value_) internal returns (bool) {
        if (!_contains(set, value_)) {
            set._values.push(value_);
            set._indexes[keccak256(value_)] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes memory value_) internal returns (bool) {
        bytes32 valueKey_ = keccak256(value_);
        uint256 valueIndex_ = set._indexes[valueKey_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                bytes memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[keccak256(lastValue_)] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[valueKey_];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes memory value_) internal view returns (bool) {
        return set._indexes[keccak256(value_)] != 0;
    }

    function _length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index_) internal view returns (bytes memory) {
        return set._values[index_];
    }

    function _values(Set storage set) internal view returns (bytes[] memory) {
        return set._values;
    }

    struct BytesSet {
        Set _inner;
    }

    function add(BytesSet storage set, bytes memory value_) internal returns (bool) {
        return _add(set._inner, value_);
    }

    function remove(BytesSet storage set, bytes memory value_) internal returns (bool) {
        return _remove(set._inner, value_);
    }

    function contains(BytesSet storage set, bytes memory value_) internal view returns (bool) {
        return _contains(set._inner, value_);
    }

    function length(BytesSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(BytesSet storage set, uint256 index_) internal view returns (bytes memory) {
        return _at(set._inner, index_);
    }

    function values(BytesSet storage set) internal view returns (bytes[] memory) {
        return _values(set._inner);
    }

    struct StringSet {
        Set _inner;
    }

    function add(StringSet storage set, string memory value_) internal returns (bool) {
        return _add(set._inner, bytes(value_));
    }

    function remove(StringSet storage set, string memory value_) internal returns (bool) {
        return _remove(set._inner, bytes(value_));
    }

    function contains(StringSet storage set, string memory value_) internal view returns (bool) {
        return _contains(set._inner, bytes(value_));
    }

    function length(StringSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(StringSet storage set, uint256 index_) internal view returns (string memory) {
        return string(_at(set._inner, index_));
    }

    function values(StringSet storage set) internal view returns (string[] memory values_) {
        bytes[] memory store_ = _values(set._inner);

        assembly {
            values_ := store_
        }
    }
}
