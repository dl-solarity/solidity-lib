// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {TypeCaster} from "../utils/TypeCaster.sol";

library Traversal {
    struct Iterator {
        uint256 treeMappingSlot;
        uint64 currentNode;
    }

    function hasNext(Iterator memory iterator_) internal view returns (bool) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        if (node_.right != 0) {
            return true;
        }

        uint64 currentNodeIndex_ = iterator_.currentNode;

        while (currentNodeIndex_ != 0) {
            AvlTree.Node memory parent_ = _getNode(iterator_.treeMappingSlot, node_.parent);

            if (currentNodeIndex_ == parent_.left) {
                return true;
            }

            currentNodeIndex_ = node_.parent;
            node_ = parent_;
        }

        return false;
    }

    function next(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        uint64 currentNodeIndex_ = iterator_.currentNode;

        require(currentNodeIndex_ != 0, "Traversal: No more nodes");

        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);

        if (node_.right != 0) {
            currentNodeIndex_ = node_.right;

            AvlTree.Node memory childNode_ = _getNode(
                iterator_.treeMappingSlot,
                currentNodeIndex_
            );

            while (childNode_.left != 0) {
                currentNodeIndex_ = childNode_.left;
                childNode_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);
            }
        } else {
            uint64 parentIndex_ = node_.parent;

            AvlTree.Node memory parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);

            while (parentIndex_ != 0 && currentNodeIndex_ == parentNode_.right) {
                currentNodeIndex_ = parentIndex_;

                parentIndex_ = parentNode_.parent;
                parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);
            }

            currentNodeIndex_ = parentIndex_;
        }

        iterator_.currentNode = currentNodeIndex_;

        return value(iterator_);
    }

    function value(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        return (node_.key, node_.value);
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

/**
 * @notice AVL Tree module
 *
 * This library provides implementation of three sets with dynamic key types:
 * `UintAVL`, `Bytes32AVL` and `Bytes32AVL`.
 *
 * Each element in the tree contains a bytes `value` field to allow storing different types
 * of values including structs
 *
 * The implementation supports setting custom comparator function
 *
 * Gas usage for _insert and _remove functions (where count is the number of elements added to the tree):
 *
 * | Statistic | _insert      | _remove          |
 * | --------- | ------------ | ---------------- |
 * | count     | 1000         | 1000             |
 * | mean      | 309,851 gas  | 164,735 gas      |
 * | min       | 162,211 gas  | 48,691 gas       |
 * | max       | 340,416 gas  | 220,653 gas      |
 *
 * ## Usage example:
 *
 * ```
 * using AvlTree for AvlTree.UintAVL;
 *
 * AvlTree.UintAVL internal uintTree;
 *
 * ................................................
 *
 * uintTree.setComparator(comparatorFunction);
 *
 * uintTree.insert(1, abi.encode(1234));
 *
 * uintTree.remove(1);
 *
 * uintTree.root();
 *
 * uintTree.treeSize();
 *
 * uintTree.inOrderTraversal();
 * ```
 */
library AvlTree {
    using TypeCaster for *;

    /**
     *********************
     *      UintAVL      *
     *********************
     */

    struct UintAVL {
        Tree _tree;
    }

    /**
     * @notice The function to set a custom comparator function, that will be used to build the uint256 tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys and values of the nodes to compare.
     */
    function setComparator(
        UintAVL storage tree,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key to insert.
     * @param value_ the value to insert.
     */
    function insert(UintAVL storage tree, uint256 key_, bytes32 value_) internal {
        _insert(tree._tree, bytes32(key_), value_);
    }

    /**
     * @notice The function to remove a node from the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(UintAVL storage tree, uint256 key_) internal {
        _remove(tree._tree, bytes32(key_));
    }

    /**
     * @notice The function to search for a node in the uint256 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key of the node to search for.
     * @return True if the node exists, false otherwise.
     */
    function search(UintAVL storage tree, uint256 key_) internal view returns (uint64) {
        return
            _search(tree._tree.tree, tree._tree.root, bytes32(key_), _getComparator(tree._tree));
    }

    /**
     * @notice The function to retrieve the value associated with a key in the uint256 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key to get the value for.
     * @return The value associated with the key.
     */
    function getValue(UintAVL storage tree, uint256 key_) internal view returns (bool, bytes32) {
        return _getValue(tree._tree, bytes32(key_));
    }

    /**
     * @notice The function to retrieve the size of the uint256 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(UintAVL storage tree) internal view returns (uint64) {
        return uint64(_treeSize(tree._tree));
    }

    function beginTraversal(
        UintAVL storage tree
    ) internal view returns (Traversal.Iterator memory) {
        return _beginTraversal(tree._tree);
    }

    function endTraversal(UintAVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _endTraversal(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the uint256 tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(UintAVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     **********************
     *     Bytes32AVL     *
     **********************
     */

    struct Bytes32AVL {
        Tree _tree;
    }

    /**
     * @notice The function to set a custom comparator function, that will be used to build the byte32 tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys and values of the nodes to compare.
     */
    function setComparator(
        Bytes32AVL storage tree,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key to insert.
     * @param value_ the value to insert.
     */
    function insert(Bytes32AVL storage tree, bytes32 key_, bytes32 value_) internal {
        _insert(tree._tree, key_, value_);
    }

    /**
     * @notice The function to remove a node from the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(Bytes32AVL storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to search for a node in the bytes32 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key of the node to search for.
     * @return True if the node exists, false otherwise.
     */
    function search(Bytes32AVL storage tree, bytes32 key_) internal view returns (uint64) {
        return _search(tree._tree.tree, tree._tree.root, key_, _getComparator(tree._tree));
    }

    /**
     * @notice The function to retrieve the value associated with a key in the bytes32 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key to get the value for.
     * @return The value associated with the key.
     */
    function getValue(
        Bytes32AVL storage tree,
        bytes32 key_
    ) internal view returns (bool, bytes32) {
        return _getValue(tree._tree, key_);
    }

    /**
     * @notice The function to retrieve the size of the bytes32 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(Bytes32AVL storage tree) internal view returns (uint64) {
        return uint64(_treeSize(tree._tree));
    }

    function beginTraversal(
        Bytes32AVL storage tree
    ) internal view returns (Traversal.Iterator memory) {
        return _beginTraversal(tree._tree);
    }

    function endTraversal(
        Bytes32AVL storage tree
    ) internal view returns (Traversal.Iterator memory) {
        return _endTraversal(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the bytes32 tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(Bytes32AVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     **********************
     *     AddressAVL     *
     **********************
     */

    struct AddressAVL {
        Tree _tree;
    }

    /**
     * @notice The function to set a custom comparator function, that will be used to build the address tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys and values of the nodes to compare.
     */
    function setComparator(
        AddressAVL storage tree,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ The key to insert.
     * @param value_ The value to insert.
     */
    function insert(AddressAVL storage tree, address key_, bytes32 value_) internal {
        _insert(tree._tree, bytes32(uint256(uint160(key_))), value_);
    }

    /**
     * @notice The function to remove a node from the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(AddressAVL storage tree, address key_) internal {
        _remove(tree._tree, bytes32(uint256(uint160(key_))));
    }

    /**
     * @notice The function to search for a node in the address tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key of the node to search for.
     * @return True if the node exists, false otherwise.
     */
    function search(AddressAVL storage tree, address key_) internal view returns (uint64) {
        return
            _search(
                tree._tree.tree,
                tree._tree.root,
                bytes32(uint256(uint160(key_))),
                _getComparator(tree._tree)
            );
    }

    /**
     * @notice The function to retrieve the value associated with a key in the address tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key to get the value for.
     * @return The value associated with the key.
     */
    function getValue(
        AddressAVL storage tree,
        address key_
    ) internal view returns (bool, bytes32) {
        return _getValue(tree._tree, bytes32(uint256(uint160(key_))));
    }

    /**
     * @notice The function to retrieve the size of the address tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(AddressAVL storage tree) internal view returns (uint64) {
        return uint64(_treeSize(tree._tree));
    }

    function beginTraversal(
        AddressAVL storage tree
    ) internal view returns (Traversal.Iterator memory) {
        return _beginTraversal(tree._tree);
    }

    function endTraversal(
        AddressAVL storage tree
    ) internal view returns (Traversal.Iterator memory) {
        return _endTraversal(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the address tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(AddressAVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     *************************
     *     Internal Tree     *
     *************************
     */

    struct Node {
        bytes32 key;
        bytes32 value;
        uint64 height;
        uint64 parent;
        uint64 left;
        uint64 right;
    }

    struct Tree {
        uint64 root;
        uint64 totalCount;
        uint64 removedCount;
        bool isCustomComparatorSet;
        mapping(uint64 => Node) tree;
        function(bytes32, bytes32) view returns (int8) comparator;
    }

    function _setComparator(
        Tree storage tree,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) private {
        require(_treeSize(tree) == 0, "AvlTree: the tree must be empty");

        tree.isCustomComparatorSet = true;

        tree.comparator = comparator_;
    }

    function _insert(Tree storage tree, bytes32 key_, bytes32 value_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(
            _search(tree.tree, tree.root, key_, _getComparator(tree)) == 0,
            "AvlTree: the node already exists"
        );

        tree.totalCount++;

        tree.root = _insertNode(
            tree.tree,
            tree.totalCount,
            tree.root,
            0,
            key_,
            value_,
            _getComparator(tree)
        );
    }

    function _remove(Tree storage tree, bytes32 key_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(
            _search(tree.tree, tree.root, key_, _getComparator(tree)) != 0,
            "AvlTree: the node doesn't exist"
        );

        tree.root = _removeNode(tree.tree, tree.root, 0, bytes32(key_), _getComparator(tree));

        tree.removedCount++;
    }

    function _insertNode(
        mapping(uint64 => Node) storage _tree,
        uint64 index_,
        uint64 node_,
        uint64 parent_,
        bytes32 key_,
        bytes32 value_,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) private returns (uint64) {
        if (_tree[node_].key == 0) {
            _tree[index_] = Node({
                key: key_,
                value: value_,
                parent: parent_,
                left: 0,
                right: 0,
                height: 1
            });

            return index_;
        }

        if (comparator_(key_, _tree[node_].key) <= 0) {
            _tree[node_].left = _insertNode(
                _tree,
                index_,
                _tree[node_].left,
                node_,
                key_,
                value_,
                comparator_
            );
        } else {
            _tree[node_].right = _insertNode(
                _tree,
                index_,
                _tree[node_].right,
                node_,
                key_,
                value_,
                comparator_
            );
        }

        return _balance(_tree, node_);
    }

    function _removeNode(
        mapping(uint64 => Node) storage _tree,
        uint64 node_,
        uint64 parent_,
        bytes32 key_,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) private returns (uint64) {
        int8 comparison_ = comparator_(key_, _tree[node_].key);

        if (comparison_ == 0) {
            uint64 left_ = _tree[node_].left;
            uint64 right_ = _tree[node_].right;

            delete _tree[node_];

            if (right_ == 0) {
                if (left_ != 0) {
                    _tree[left_].parent = parent_;
                }

                return left_;
            }

            uint64 temp_;

            for (temp_ = right_; _tree[temp_].left != 0; temp_ = _tree[temp_].left) {}

            _tree[temp_].right = _removeMin(_tree, right_);
            _tree[temp_].left = left_;

            if (left_ != 0) {
                _tree[left_].parent = temp_;
            }

            return _balance(_tree, temp_);
        } else if (comparison_ < 0) {
            _tree[node_].left = _removeNode(_tree, _tree[node_].left, node_, key_, comparator_);
        } else {
            _tree[node_].right = _removeNode(_tree, _tree[node_].right, node_, key_, comparator_);
        }

        return _balance(_tree, node_);
    }

    function _removeMin(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        if (_node.left == 0) {
            if (_node.right != 0) {
                _tree[_node.right].parent = _node.parent;
            }

            return _node.right;
        }

        _node.left = _removeMin(_tree, _node.left);

        return _balance(_tree, node_);
    }

    function _rotateLeft(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        uint64 temp_ = _node.left;

        _tree[temp_].parent = _node.parent;
        _node.parent = temp_;

        if (_tree[temp_].right != 0) {
            _tree[_tree[temp_].right].parent = node_;
        }

        _node.left = _tree[temp_].right;
        _tree[temp_].right = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _rotateRight(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        uint64 temp_ = _node.right;

        _tree[temp_].parent = _node.parent;
        _node.parent = temp_;

        if (_tree[temp_].left != 0) {
            _tree[_tree[temp_].left].parent = node_;
        }

        _node.right = _tree[temp_].left;
        _tree[temp_].left = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _balance(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        _updateHeight(_tree, node_);

        Node storage _left = _tree[_tree[node_].left];
        Node storage _right = _tree[_tree[node_].right];

        if (_left.height > _right.height + 1) {
            if (_tree[_left.right].height > _tree[_left.left].height) {
                _tree[node_].left = _rotateRight(_tree, _tree[node_].left);
            }

            return _rotateLeft(_tree, node_);
        } else if (_right.height > _left.height + 1) {
            if (_tree[_right.left].height > _tree[_right.right].height) {
                _tree[node_].right = _rotateLeft(_tree, _tree[node_].right);
            }

            return _rotateRight(_tree, node_);
        }

        return node_;
    }

    function _updateHeight(mapping(uint64 => Node) storage _tree, uint64 node_) private {
        Node storage _node = _tree[node_];

        _node.height = uint64(1 + Math.max(_tree[_node.left].height, _tree[_node.right].height));
    }

    function _search(
        mapping(uint64 => Node) storage _tree,
        uint64 node_,
        bytes32 key_,
        function(bytes32, bytes32) view returns (int8) comparator_
    ) private view returns (uint64) {
        if (node_ == 0) {
            return 0;
        }

        int8 comparison_ = comparator_(key_, _tree[node_].key);

        if (comparison_ == 0) {
            return node_;
        } else if (comparison_ < 0) {
            return _search(_tree, _tree[node_].left, key_, comparator_);
        } else {
            return _search(_tree, _tree[node_].right, key_, comparator_);
        }
    }

    function _getValue(Tree storage tree, bytes32 key_) private view returns (bool, bytes32) {
        uint64 index_ = _search(tree.tree, tree.root, key_, _getComparator(tree));

        if (index_ == 0) {
            return (false, 0);
        }

        return (true, tree.tree[index_].value);
    }

    function _treeSize(Tree storage tree) private view returns (uint256) {
        return tree.totalCount - tree.removedCount;
    }

    function _beginTraversal(Tree storage tree) private view returns (Traversal.Iterator memory) {
        uint256 treeMappingSlot_;
        assembly {
            treeMappingSlot_ := add(tree.slot, 1)
        }

        uint64 root_ = tree.root;

        if (root_ == 0) {
            return Traversal.Iterator({treeMappingSlot: treeMappingSlot_, currentNode: 0});
        }

        uint64 current_ = root_;
        while (tree.tree[current_].left != 0) {
            current_ = tree.tree[current_].left;
        }

        return Traversal.Iterator({treeMappingSlot: treeMappingSlot_, currentNode: current_});
    }

    function _endTraversal(Tree storage tree) private pure returns (Traversal.Iterator memory) {
        uint256 treeMappingSlot_;
        assembly {
            treeMappingSlot_ := add(tree.slot, 1)
        }

        return Traversal.Iterator({treeMappingSlot: treeMappingSlot_, currentNode: 0});
    }

    function _getComparator(
        Tree storage tree
    ) private view returns (function(bytes32, bytes32) view returns (int8)) {
        return tree.isCustomComparatorSet ? tree.comparator : _defaultComparator;
    }

    function _defaultComparator(bytes32 key1_, bytes32 key2_) private pure returns (int8) {
        if (key1_ < key2_) {
            return -1;
        }

        if (key1_ > key2_) {
            return 1;
        }

        return 0;
    }
}
