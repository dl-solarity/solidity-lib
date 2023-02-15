// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PriorityQueue {
    /**
     ************************
     *      UintQueue       *
     ************************
     */

    struct UintQueue {
        Queue _queue;
    }

    function add(UintQueue storage queue, uint256 value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(value_), priority_);
    }

    function remove(UintQueue storage queue, uint256 index_) internal {
        _remove(queue._queue, index_);
    }

    function removeTop(UintQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    function top(UintQueue storage queue) internal view returns (uint256) {
        return uint256(_top(queue._queue));
    }

    function length(UintQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    function values(UintQueue storage queue) internal view returns (uint256[] memory result_) {
        bytes32[] memory vals_ = _values(queue._queue);

        assembly {
            result_ := vals_
        }
    }

    function priorities(UintQueue storage queue) internal view returns (uint256[] memory) {
        return _priorities(queue._queue);
    }

    /**
     ************************
     *     Bytes32Queue     *
     ************************
     */

    struct Bytes32Queue {
        Queue _queue;
    }

    function add(Bytes32Queue storage queue, bytes32 value_, uint256 priority_) internal {
        _add(queue._queue, value_, priority_);
    }

    function remove(Bytes32Queue storage queue, uint256 index_) internal {
        _remove(queue._queue, index_);
    }

    function removeTop(Bytes32Queue storage queue) internal {
        _removeTop(queue._queue);
    }

    function top(Bytes32Queue storage queue) internal view returns (bytes32) {
        return _top(queue._queue);
    }

    function length(Bytes32Queue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    function values(Bytes32Queue storage queue) internal view returns (bytes32[] memory result_) {
        result_ = _values(queue._queue);
    }

    function priorities(Bytes32Queue storage queue) internal view returns (uint256[] memory) {
        return _priorities(queue._queue);
    }

    /**
     ************************
     *     AddressQueue     *
     ************************
     */

    struct AddressQueue {
        Queue _queue;
    }

    function add(AddressQueue storage queue, address value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(uint256(uint160(value_))), priority_);
    }

    function remove(AddressQueue storage queue, uint256 index_) internal {
        _remove(queue._queue, index_);
    }

    function removeTop(AddressQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    function top(AddressQueue storage queue) internal view returns (address) {
        return address(uint160(uint256(_top(queue._queue))));
    }

    function length(AddressQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    function values(AddressQueue storage queue) internal view returns (address[] memory result_) {
        bytes32[] memory vals_ = _values(queue._queue);

        assembly {
            result_ := vals_
        }
    }

    function priorities(AddressQueue storage queue) internal view returns (uint256[] memory) {
        return _priorities(queue._queue);
    }

    /**
     ************************
     *        Queue         *
     ************************
     */

    struct Queue {
        bytes32[] _values;
        uint256[] _priorities;
    }

    function _add(Queue storage queue, bytes32 value_, uint256 priority_) private {
        queue._values.push(value_);
        queue._priorities.push(priority_);

        _shiftUp(queue, queue._values.length - 1);
    }

    function _remove(Queue storage queue, uint256 index_) private {
        if (index_ > 0) {
            queue._priorities[index_] = queue._priorities[0] + 1;

            _shiftUp(queue, index_);
        }

        _removeTop(queue);
    }

    function _removeTop(Queue storage queue) private {
        uint256 length_ = queue._values.length;

        queue._values[0] = queue._values[length_ - 1];
        queue._priorities[0] = queue._priorities[length_ - 1];

        queue._values.pop();
        queue._priorities.pop();

        _shiftDown(queue, 0);
    }

    function _top(Queue storage queue) private view returns (bytes32) {
        return queue._values[0];
    }

    function _length(Queue storage queue) private view returns (uint256) {
        return queue._values.length;
    }

    function _values(Queue storage queue) private view returns (bytes32[] memory) {
        return queue._values;
    }

    function _priorities(Queue storage queue) private view returns (uint256[] memory) {
        return queue._priorities;
    }

    function _shiftUp(Queue storage queue, uint256 index_) private {
        while (index_ > 0) {
            uint256 parent_ = _parent(index_);

            if (queue._priorities[parent_] < queue._priorities[index_]) {
                break;
            }

            _swap(queue, parent_, index_);

            index_ = parent_;
        }
    }

    function _shiftDown(Queue storage queue, uint256 index_) private {
        while (true) {
            uint256 maxIndex_ = _maxPriorityIndex(queue, index_);

            if (index_ == maxIndex_) {
                break;
            }

            _swap(queue, maxIndex_, index_);

            index_ = maxIndex_;
        }
    }

    function _swap(Queue storage queue, uint256 index1_, uint256 index2_) private {
        bytes32[] storage _vals = queue._values;
        uint256[] storage _priors = queue._priorities;

        (_vals[index1_], _vals[index2_]) = (_vals[index2_], _vals[index1_]);
        (_priors[index1_], _priors[index2_]) = (_priors[index2_], _priors[index1_]);
    }

    function _maxPriorityIndex(
        Queue storage queue,
        uint256 index_
    ) private view returns (uint256) {
        uint256[] storage _priors = queue._priorities;

        uint256 length_ = _priors.length;
        uint256 maxIndex_ = index_;

        uint256 child_ = _leftChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        child_ = _rightChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        return maxIndex_;
    }

    function _parent(uint256 index_) private pure returns (uint256) {
        return (index_ - 1) / 2;
    }

    function _leftChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 1;
    }

    function _rightChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 2;
    }
}
