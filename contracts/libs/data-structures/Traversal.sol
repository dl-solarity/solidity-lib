// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AvlTree} from "./AvlTree.sol";

/**
 * @notice Traversal module
 *
 * This library provides functions to perform an in-order traversal of the AVL Tree
 */
library Traversal {
    /**
     * @notice Iterator struct to keep track of the current position in the tree.
     * @param treeMappingSlot The storage slot of the tree mapping.
     * @param currentNode The index of the current node in the traversal.
     */
    struct Iterator {
        uint256 treeMappingSlot;
        uint64 currentNode;
    }

    error NoNodesLeft();

    /**
     * @notice The function to check if the iterator is currently valid (has not reached the end of the traversal).
     * @param iterator_ self.
     * @return True if the iterator is valid, false otherwise.
     */
    function isValid(Iterator memory iterator_) internal pure returns (bool) {
        return iterator_.currentNode != 0;
    }

    /**
     * @notice The function to check if there is a next node in the traversal.
     * @param iterator_ self.
     * @return True if there is a next node, false otherwise.
     */
    function hasNext(Iterator memory iterator_) internal view returns (bool) {
        return _has(iterator_, true);
    }

    /**
     * @notice The function to check if there is a previous node in the traversal.
     * @param iterator_ self.
     * @return True if there is a previous node, false otherwise.
     */
    function hasPrev(Iterator memory iterator_) internal view returns (bool) {
        return _has(iterator_, false);
    }

    /**
     * @notice The function to move the iterator to the next node and retrieve its key and value.
     * @param iterator_ self.
     * @return The key of the next node.
     * @return The value of the next node.
     */
    function next(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        return _moveToAdjacent(iterator_, true);
    }

    /**
     * @notice The function to move the iterator to the previous node and retrieve its key and value.
     * @param iterator_ self.
     * @return The key of the previous node.
     * @return The value of the previous node.
     */
    function prev(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        return _moveToAdjacent(iterator_, false);
    }

    /**
     * @notice The function to retrieve the key and value of the current node.
     * @param iterator_ self.
     * @return The key of the current node.
     * @return The value of the current node.
     */
    function value(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        return (node_.key, node_.value);
    }

    function _has(Iterator memory iterator_, bool next_) private view returns (bool) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        if (_adjacent(node_, next_) != 0) {
            return true;
        }

        uint64 currentNodeIndex_ = iterator_.currentNode;

        while (currentNodeIndex_ != 0) {
            AvlTree.Node memory parent_ = _getNode(iterator_.treeMappingSlot, node_.parent);

            if (currentNodeIndex_ == _adjacent(parent_, !next_)) {
                return true;
            }

            currentNodeIndex_ = node_.parent;
            node_ = parent_;
        }

        return false;
    }

    function _moveToAdjacent(
        Iterator memory iterator_,
        bool next_
    ) internal view returns (bytes32, bytes32) {
        uint64 currentNodeIndex_ = iterator_.currentNode;

        if (currentNodeIndex_ == 0) revert NoNodesLeft();

        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);

        if (_adjacent(node_, next_) != 0) {
            currentNodeIndex_ = _adjacent(node_, next_);

            AvlTree.Node memory childNode_ = _getNode(
                iterator_.treeMappingSlot,
                currentNodeIndex_
            );

            while (_adjacent(childNode_, !next_) != 0) {
                currentNodeIndex_ = _adjacent(childNode_, !next_);
                childNode_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);
            }
        } else {
            uint64 parentIndex_ = node_.parent;

            AvlTree.Node memory parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);

            while (parentIndex_ != 0 && currentNodeIndex_ == _adjacent(parentNode_, next_)) {
                currentNodeIndex_ = parentIndex_;

                parentIndex_ = parentNode_.parent;
                parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);
            }

            currentNodeIndex_ = parentIndex_;
        }

        iterator_.currentNode = currentNodeIndex_;

        return value(iterator_);
    }

    function _adjacent(AvlTree.Node memory node_, bool next_) private pure returns (uint64) {
        return next_ ? node_.right : node_.left;
    }

    function _getNode(
        uint256 slot_,
        uint64 index_
    ) private view returns (AvlTree.Node memory node_) {
        bytes32 baseSlot_ = keccak256(abi.encode(index_, slot_));

        assembly {
            let valueSlot_ := add(baseSlot_, 1)
            let packedSlot_ := add(baseSlot_, 2)

            let packedData_ := sload(packedSlot_)

            mstore(node_, sload(baseSlot_))
            mstore(add(node_, 0x20), sload(valueSlot_))
            mstore(add(node_, 0x40), and(packedData_, 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0x60), and(shr(64, packedData_), 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0x80), and(shr(128, packedData_), 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0xa0), and(shr(192, packedData_), 0xFFFFFFFFFFFFFFFF))
        }

        return node_;
    }
}
