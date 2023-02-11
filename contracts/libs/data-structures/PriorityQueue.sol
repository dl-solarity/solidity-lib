// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PriorityQueue {
    struct Queue {
        bytes32[] _values;
        uint256[] _priorities;
    }

    function add(Queue storage queue, bytes32 value_, uint256 priority_) internal {
        queue._values.push(value_);
        queue._priorities.push(priority_);

        _shiftUp(queue, queue._values.length - 1);
    }

    function remove(Queue storage queue, uint256 index_) internal {
        if (index_ > 0) {
            queue._priorities[index_] = queue._priorities[0] + 1;

            _shiftUp(queue, index_);
        }

        removeTop(queue);
    }

    function removeTop(Queue storage queue) internal {
        uint256 length_ = queue._values.length;

        queue._values[0] = queue._values[length_ - 1];
        queue._priorities[0] = queue._priorities[length_ - 1];

        queue._values.pop();
        queue._priorities.pop();

        _shiftDown(queue, 0);
    }

    function top(Queue storage queue) internal view returns (bytes32) {
        return queue._values[0];
    }

    function values(Queue storage queue) internal view returns (bytes32[] memory) {
        return queue._values;
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
        bytes32[] storage _values = queue._values;
        uint256[] storage _priorities = queue._priorities;

        (_values[index1_], _values[index2_]) = (_values[index2_], _values[index1_]);
        (_priorities[index1_], _priorities[index2_]) = (
            _priorities[index2_],
            _priorities[index1_]
        );
    }

    function _maxPriorityIndex(
        Queue storage queue,
        uint256 index_
    ) private view returns (uint256) {
        uint256[] storage _priorities = queue._priorities;

        uint256 length_ = _priorities.length;
        uint256 maxIndex_ = index_;

        uint256 child_ = _leftChild(index_);

        if (child_ < length_ && _priorities[child_] > _priorities[maxIndex_]) {
            maxIndex_ = child_;
        }

        child_ = _rightChild(index_);

        if (child_ < length_ && _priorities[child_] > _priorities[maxIndex_]) {
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
