// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {TypeCaster} from "../utils/TypeCaster.sol";

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
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
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
    function insert(UintAVL storage tree, uint256 key_, bytes memory value_) internal {
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
    function search(UintAVL storage tree, uint256 key_) internal view returns (bool) {
        return _search(tree._tree, bytes32(key_));
    }

    /**
     * @notice The function to retrieve the value associated with a key in the uint256 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key to get the value for.
     * @return The value associated with the key.
     */
    function getValue(UintAVL storage tree, uint256 key_) internal view returns (bytes storage) {
        require(_search(tree._tree, bytes32(key_)), "AvlTree: node with such key doesn't exist");

        return tree._tree.tree[bytes32(key_)].value;
    }

    /**
     * @notice The function to retrieve the minimum key in the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The minimum key in the tree.
     */
    function getMin(UintAVL storage tree) internal view returns (uint256) {
        return uint256(_getMin(tree._tree.tree, tree._tree.root));
    }

    /**
     * @notice The function to retrieve the maximum key in the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The maximum key in the tree.
     */
    function getMax(UintAVL storage tree) internal view returns (uint256) {
        return uint256(_getMax(tree._tree.tree, tree._tree.root));
    }

    /**
     * @notice The function to return the key of the root element of the uint256 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The key of the root element of the uint256 tree.
     */
    function root(UintAVL storage tree) internal view returns (uint256) {
        return uint256(tree._tree.root);
    }

    /**
     * @notice The function to retrieve the size of the uint256 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(UintAVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    /**
     * @notice The function to perform an in-order traversal of the uint256 tree.
     * @param tree self.
     * @return An array of keys in in-order traversal.
     */
    function inOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        return _getTraversal(tree._tree, _inOrderTraversal).asUint256Array();
    }

    /**
     * @notice The function to perform an pre-order traversal of the uint256 tree.
     * @param tree self.
     * @return An array of keys in pre-order traversal.
     */
    function preOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        return _getTraversal(tree._tree, _preOrderTraversal).asUint256Array();
    }

    /**
     * @notice The function to perform an post-order traversal of the uint256 tree.
     * @param tree self.
     * @return An array of keys in post-order traversal.
     */
    function postOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        return _getTraversal(tree._tree, _postOrderTraversal).asUint256Array();
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
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
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
    function insert(Bytes32AVL storage tree, bytes32 key_, bytes memory value_) internal {
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
    function search(Bytes32AVL storage tree, bytes32 key_) internal view returns (bool) {
        return _search(tree._tree, key_);
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
    ) internal view returns (bytes storage) {
        require(_search(tree._tree, key_), "AvlTree: node with such key doesn't exist");
        return tree._tree.tree[key_].value;
    }

    /**
     * @notice The function to retrieve the minimum key in the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The minimum key in the tree.
     */
    function getMin(Bytes32AVL storage tree) internal view returns (bytes32) {
        return _getMin(tree._tree.tree, tree._tree.root);
    }

    /**
     * @notice The function to retrieve the maximum key in the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The maximum key in the tree.
     */
    function getMax(Bytes32AVL storage tree) internal view returns (bytes32) {
        return _getMax(tree._tree.tree, tree._tree.root);
    }

    /**
     * @notice The function to return the key of the root element of the bytes32 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The key of the root element of the uint256 tree.
     */
    function root(Bytes32AVL storage tree) internal view returns (bytes32) {
        return tree._tree.root;
    }

    /**
     * @notice The function to retrieve the size of the bytes32 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(Bytes32AVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    /**
     * @notice The function to perform an in-order traversal of the bytes32 tree.
     * @param tree self.
     * @return An array of keys in in-order traversal.
     */
    function inOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _inOrderTraversal);
    }

    /**
     * @notice The function to perform an pre-order traversal of the bytes32 tree.
     * @param tree self.
     * @return An array of keys in pre-order traversal.
     */
    function preOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _preOrderTraversal);
    }

    /**
     * @notice The function to perform an post-order traversal of the bytes32 tree.
     * @param tree self.
     * @return An array of keys in post-order traversal.
     */
    function postOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _postOrderTraversal);
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
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
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
    function insert(AddressAVL storage tree, address key_, bytes memory value_) internal {
        _insert(tree._tree, _asBytes32(key_), value_);
    }

    /**
     * @notice The function to remove a node from the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(AddressAVL storage tree, address key_) internal {
        _remove(tree._tree, _asBytes32(key_));
    }

    /**
     * @notice The function to search for a node in the address tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param key_ the key of the node to search for.
     * @return True if the node exists, false otherwise.
     */
    function search(AddressAVL storage tree, address key_) internal view returns (bool) {
        return _search(tree._tree, _asBytes32(key_));
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
    ) internal view returns (bytes storage) {
        require(
            _search(tree._tree, _asBytes32(key_)),
            "AvlTree: node with such key doesn't exist"
        );
        return tree._tree.tree[_asBytes32(key_)].value;
    }

    /**
     * @notice The function to retrieve the minimum key in the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The minimum key in the tree.
     */
    function getMin(AddressAVL storage tree) internal view returns (address) {
        return _asAddress(_getMin(tree._tree.tree, tree._tree.root));
    }

    /**
     * @notice The function to retrieve the maximum key in the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @return The maximum key in the tree.
     */
    function getMax(AddressAVL storage tree) internal view returns (address) {
        return _asAddress(_getMax(tree._tree.tree, tree._tree.root));
    }

    /**
     * @notice The function to return the key of the root element of the address tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The key of the root element of the uint256 tree.
     */
    function root(AddressAVL storage tree) internal view returns (address) {
        return _asAddress(tree._tree.root);
    }

    /**
     * @notice The function to retrieve the size of the address tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function treeSize(AddressAVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    /**
     * @notice The function to perform an in-order traversal of the address tree.
     * @param tree self.
     * @return An array of keys in in-order traversal.
     */
    function inOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        return _getTraversal(tree._tree, _inOrderTraversal).asAddressArray();
    }

    /**
     * @notice The function to perform an pre-order traversal of the address tree.
     * @param tree self.
     * @return An array of keys in pre-order traversal.
     */
    function preOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        return _getTraversal(tree._tree, _preOrderTraversal).asAddressArray();
    }

    /**
     * @notice The function to perform an post-order traversal of the address tree.
     * @param tree self.
     * @return An array of keys in post-order traversal.
     */
    function postOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        return _getTraversal(tree._tree, _postOrderTraversal).asAddressArray();
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
        bytes value;
        uint256 height;
        bytes32 left;
        bytes32 right;
    }

    struct Tree {
        bytes32 root;
        uint256 treeSize;
        bool isCustomComparatorSet;
        mapping(bytes32 => Node) tree;
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator;
    }

    function _setComparator(
        Tree storage tree,
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
    ) private {
        require(tree.treeSize == 0, "AvlTree: the tree must be empty");

        tree.isCustomComparatorSet = true;

        tree.comparator = comparator_;
    }

    function _insert(Tree storage tree, bytes32 key_, bytes memory value_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(tree.tree[key_].key != key_, "AvlTree: the node already exists");

        tree.root = _insertNode(tree.tree, tree.root, key_, value_, _getComparator(tree));

        tree.treeSize++;
    }

    function _remove(Tree storage tree, bytes32 key_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(tree.tree[key_].key == key_, "AvlTree: the node doesn't exist");

        tree.root = _removeNode(tree.tree, tree.root, key_, _getComparator(tree));

        tree.treeSize--;
    }

    function _insertNode(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32 key_,
        bytes memory value_,
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
    ) private returns (bytes32) {
        if (node_ == 0) {
            _tree[key_] = Node({key: key_, value: value_, left: 0, right: 0, height: 1});

            return key_;
        }

        if (comparator_(key_, node_, value_, _tree[node_].value) <= 0) {
            _tree[node_].left = _insertNode(_tree, _tree[node_].left, key_, value_, comparator_);
        } else {
            _tree[node_].right = _insertNode(_tree, _tree[node_].right, key_, value_, comparator_);
        }

        return _balance(_tree, node_);
    }

    function _removeNode(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32 key_,
        function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8) comparator_
    ) private returns (bytes32) {
        if (comparator_(key_, node_, _tree[key_].value, _tree[node_].value) == 0) {
            bytes32 left_ = _tree[node_].left;
            bytes32 right_ = _tree[node_].right;

            delete _tree[node_];

            if (right_ == 0) {
                return left_;
            }

            bytes32 temp_;

            for (temp_ = right_; _tree[temp_].left != 0; temp_ = _tree[temp_].left) {}

            _tree[temp_].right = _removeMin(_tree, right_);
            _tree[temp_].left = left_;

            return _balance(_tree, temp_);
        } else if (comparator_(key_, node_, _tree[key_].value, _tree[node_].value) < 0) {
            _tree[node_].left = _removeNode(_tree, _tree[node_].left, key_, comparator_);
        } else {
            _tree[node_].right = _removeNode(_tree, _tree[node_].right, key_, comparator_);
        }

        return _balance(_tree, node_);
    }

    function _removeMin(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private returns (bytes32) {
        Node storage _node = _tree[node_];

        if (_node.left == 0) {
            return _node.right;
        }

        _node.left = _removeMin(_tree, _node.left);

        return _balance(_tree, node_);
    }

    function _rotateLeft(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private returns (bytes32) {
        Node storage _node = _tree[node_];

        bytes32 temp_ = _node.left;
        _node.left = _tree[temp_].right;
        _tree[temp_].right = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _rotateRight(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private returns (bytes32) {
        Node storage _node = _tree[node_];

        bytes32 temp_ = _node.right;
        _node.right = _tree[temp_].left;
        _tree[temp_].left = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _balance(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private returns (bytes32) {
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

    function _updateHeight(mapping(bytes32 => Node) storage _tree, bytes32 node_) private {
        Node storage _node = _tree[node_];

        _node.height = 1 + Math.max(_tree[_node.left].height, _tree[_node.right].height);
    }

    function _search(Tree storage tree, bytes32 key_) private view returns (bool) {
        return key_ != 0 && tree.tree[key_].key == key_;
    }

    function _getMin(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private view returns (bytes32) {
        while (_tree[node_].left != 0) {
            node_ = _tree[node_].left;
        }

        return node_;
    }

    function _getMax(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private view returns (bytes32) {
        while (_tree[node_].right != 0) {
            node_ = _tree[node_].right;
        }

        return node_;
    }

    function _getTraversal(
        Tree storage tree,
        function(mapping(bytes32 => Node) storage, bytes32, bytes32[] memory, uint256)
            view
            returns (uint256) traversalFunction_
    ) private view returns (bytes32[] memory) {
        bytes32[] memory keys_ = new bytes32[](tree.treeSize);

        traversalFunction_(tree.tree, tree.root, keys_, 0);

        return keys_;
    }

    function _inOrderTraversal(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32[] memory keys_,
        uint256 index_
    ) private view returns (uint256) {
        if (node_ == 0) {
            return index_;
        }

        index_ = _inOrderTraversal(_tree, _tree[node_].left, keys_, index_);

        if (_tree[node_].key != 0) {
            keys_[index_++] = _tree[node_].key;
        }

        index_ = _inOrderTraversal(_tree, _tree[node_].right, keys_, index_);

        return index_;
    }

    function _preOrderTraversal(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32[] memory keys_,
        uint256 index_
    ) private view returns (uint256) {
        if (node_ == 0) {
            return index_;
        }

        if (_tree[node_].key != 0) {
            keys_[index_++] = _tree[node_].key;
        }

        index_ = _preOrderTraversal(_tree, _tree[node_].left, keys_, index_);
        index_ = _preOrderTraversal(_tree, _tree[node_].right, keys_, index_);

        return index_;
    }

    function _postOrderTraversal(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32[] memory keys_,
        uint256 index_
    ) private view returns (uint256) {
        if (node_ == 0) {
            return index_;
        }

        index_ = _postOrderTraversal(_tree, _tree[node_].left, keys_, index_);
        index_ = _postOrderTraversal(_tree, _tree[node_].right, keys_, index_);

        if (_tree[node_].key != 0) {
            keys_[index_++] = _tree[node_].key;
        }

        return index_;
    }

    function _getComparator(
        Tree storage tree
    )
        private
        view
        returns (function(bytes32, bytes32, bytes memory, bytes memory) view returns (int8))
    {
        return tree.isCustomComparatorSet ? tree.comparator : _defaultComparator;
    }

    function _defaultComparator(
        bytes32 key1_,
        bytes32 key2_,
        bytes memory,
        bytes memory
    ) private pure returns (int8) {
        if (key1_ < key2_) return -1;
        if (key1_ > key2_) return 1;
        return 0;
    }

    function _asAddress(bytes32 from_) private pure returns (address to_) {
        assembly {
            to_ := from_
        }
    }

    function _asBytes32(address from_) private pure returns (bytes32 to_) {
        assembly {
            to_ := from_
        }
    }
}
