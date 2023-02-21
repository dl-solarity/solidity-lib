// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Vector {
    struct Vector {
        uint256 _allocation;
        uint256 _dataPointer;
    }

    function init() internal pure returns (Vector memory self) {
        uint256 dataPointer_ = _allocate(5);

        _clean(dataPointer_, 1);

        self._allocation = 5;
        self._dataPointer = dataPointer_;
    }

    function init(uint256 length_) internal pure returns (Vector memory self) {
        uint256 allocation_ = length_ + 1;
        uint256 dataPointer_ = _allocate(allocation_);

        _clean(dataPointer_, allocation_);

        self._allocation = allocation_;
        self._dataPointer = dataPointer_;

        assembly {
            mstore(dataPointer_, length_)
        }
    }

    function init(bytes32[] memory array_) internal pure returns (Vector memory self) {
        assembly {
            mstore(self, add(mload(array_), 0x1))
            mstore(add(self, 0x20), array_)
        }
    }

    function push(Vector memory self, bytes32 value_) internal pure {
        uint256 length_ = length(self);

        if (length_ + 1 == self._allocation) {
            _resize(self, self._allocation * 2);
        }

        assembly {
            let dataPointer_ := mload(add(self, 0x20))

            mstore(dataPointer_, add(length_, 0x1))
            mstore(add(dataPointer_, add(mul(length_, 0x20), 0x20)), value_)
        }
    }

    function pop(Vector memory self) internal pure {
        uint256 length_ = length(self);

        require(length_ > 0, "Vector: empty vector");

        assembly {
            mstore(mload(add(self, 0x20)), sub(length_, 0x1))
        }
    }

    function set(Vector memory self, uint256 index_, bytes32 value_) internal pure {
        _requireInBounds(self, index_);

        assembly {
            mstore(add(mload(add(self, 0x20)), add(mul(index_, 0x20), 0x20)), value_)
        }
    }

    function at(Vector memory self, uint256 index_) internal pure returns (bytes32 value_) {
        _requireInBounds(self, index_);

        assembly {
            value_ := mload(add(mload(add(self, 0x20)), add(mul(index_, 0x20), 0x20)))
        }
    }

    function length(Vector memory self) internal pure returns (uint256 length_) {
        assembly {
            length_ := mload(mload(add(self, 0x20)))
        }
    }

    function toArray(Vector memory self) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := mload(add(self, 0x20))
        }
    }

    function _resize(Vector memory self, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(self, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(self, newAllocation_)
            mstore(add(self, 0x20), newDataPointer_)
        }
    }

    function _requireInBounds(Vector memory self, uint256 index_) private pure {
        require(index_ < length(self), "Vector: out of bounds");
    }

    function _clean(uint256 dataPointer_, uint256 slots_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, mul(slots_, 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(dataPointer_, i), 0x0)
            }
        }
    }

    function _allocate(uint256 allocation_) private pure returns (uint256 pointer_) {
        assembly {
            pointer_ := mload(0x40)
            mstore(0x40, add(pointer_, mul(allocation_, 0x20)))
        }
    }
}
