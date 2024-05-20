// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice The implementation of AVL tree.
 */
library AvlTree {
    /**
     *********************
     *      UintAVL      *
     *********************
     */

    struct UintAVL {
        Tree _tree;
    }

    function setComparator(
        UintAVL storage tree,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    function insert(UintAVL storage tree, uint256 value_) internal {
        _insert(tree._tree, bytes32(value_));
    }

    function remove(UintAVL storage tree, uint256 value_) internal {
        _remove(tree._tree, bytes32(value_));
    }

    function search(UintAVL storage tree, uint256 value_) internal view returns (bool) {
        return _search(tree._tree, bytes32(value_));
    }

    function getMin(UintAVL storage tree) internal view returns (uint256) {
        return uint256(_getMin(tree._tree.tree, tree._tree.root));
    }

    function getMax(UintAVL storage tree) internal view returns (uint256) {
        return uint256(_getMax(tree._tree.tree, tree._tree.root));
    }

    function root(UintAVL storage tree) internal view returns (uint256) {
        return uint256(tree._tree.root);
    }

    function treeSize(UintAVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    function inOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _inOrderTraversal);
        uint256[] memory uintTraversal_ = new uint256[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            uintTraversal_[i] = uint256(bytesTraversal_[i]);
        }

        return uintTraversal_;
    }

    function preOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _preOrderTraversal);
        uint256[] memory uintTraversal_ = new uint256[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            uintTraversal_[i] = uint256(bytesTraversal_[i]);
        }

        return uintTraversal_;
    }

    function postOrderTraversal(UintAVL storage tree) internal view returns (uint256[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _postOrderTraversal);
        uint256[] memory uintTraversal_ = new uint256[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            uintTraversal_[i] = uint256(bytesTraversal_[i]);
        }

        return uintTraversal_;
    }

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

    function setComparator(
        Bytes32AVL storage tree,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    function insert(Bytes32AVL storage tree, bytes32 value_) internal {
        _insert(tree._tree, value_);
    }

    function remove(Bytes32AVL storage tree, bytes32 value_) internal {
        _remove(tree._tree, value_);
    }

    function search(Bytes32AVL storage tree, bytes32 value_) internal view returns (bool) {
        return _search(tree._tree, value_);
    }

    function getMin(Bytes32AVL storage tree) internal view returns (bytes32) {
        return _getMin(tree._tree.tree, tree._tree.root);
    }

    function getMax(Bytes32AVL storage tree) internal view returns (bytes32) {
        return _getMax(tree._tree.tree, tree._tree.root);
    }

    function root(Bytes32AVL storage tree) internal view returns (bytes32) {
        return tree._tree.root;
    }

    function treeSize(Bytes32AVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    function inOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _inOrderTraversal);
    }

    function preOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _preOrderTraversal);
    }

    function postOrderTraversal(Bytes32AVL storage tree) internal view returns (bytes32[] memory) {
        return _getTraversal(tree._tree, _postOrderTraversal);
    }

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

    function setComparator(
        AddressAVL storage tree,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    function insert(AddressAVL storage tree, address value_) internal {
        _insert(tree._tree, bytes32(uint256(uint160(value_))));
    }

    function remove(AddressAVL storage tree, address value_) internal {
        _remove(tree._tree, bytes32(uint256(uint160(value_))));
    }

    function search(AddressAVL storage tree, address value_) private view returns (bool) {
        return _search(tree._tree, bytes32(uint256(uint160(value_))));
    }

    function getMin(AddressAVL storage tree) private view returns (address) {
        return address(uint160(uint256(_getMin(tree._tree.tree, tree._tree.root))));
    }

    function getMax(AddressAVL storage tree) private view returns (address) {
        return address(uint160(uint256(_getMax(tree._tree.tree, tree._tree.root))));
    }

    function root(AddressAVL storage tree) internal view returns (address) {
        return address(uint160(uint256(tree._tree.root)));
    }

    function treeSize(AddressAVL storage tree) internal view returns (uint256) {
        return tree._tree.treeSize;
    }

    function inOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _inOrderTraversal);
        address[] memory addressTraversal_ = new address[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            addressTraversal_[i] = address(uint160(uint256(bytesTraversal_[i])));
        }

        return addressTraversal_;
    }

    function preOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _preOrderTraversal);
        address[] memory addressTraversal_ = new address[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            addressTraversal_[i] = address(uint160(uint256(bytesTraversal_[i])));
        }

        return addressTraversal_;
    }

    function postOrderTraversal(AddressAVL storage tree) internal view returns (address[] memory) {
        bytes32[] memory bytesTraversal_ = _getTraversal(tree._tree, _postOrderTraversal);
        address[] memory addressTraversal_ = new address[](bytesTraversal_.length);

        for (uint256 i = 0; i < bytesTraversal_.length; i++) {
            addressTraversal_[i] = address(uint160(uint256(bytesTraversal_[i])));
        }

        return addressTraversal_;
    }

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
        uint256 height;
        bytes32 left;
        bytes32 right;
    }

    struct Tree {
        mapping(bytes32 => Node) tree;
        bytes32 root;
        uint256 treeSize;
        bool isCustomComparatorSet;
        function(bytes32, bytes32) pure returns (int8) comparator;
    }

    function _setComparator(
        Tree storage tree,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) private {
        require(tree.treeSize == 0, "AvlTree: the tree must be empty");

        tree.isCustomComparatorSet = true;

        tree.comparator = comparator_;
    }

    function _insert(Tree storage tree, bytes32 key_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(tree.tree[key_].key != key_, "AvlSegmentTree: the node already exists");

        function(bytes32, bytes32) pure returns (int8) comparator_ = tree.isCustomComparatorSet
            ? tree.comparator
            : _defaultComparator;

        tree.root = _insertNode(tree.tree, tree.root, key_, comparator_);

        tree.treeSize++;
    }

    function _remove(Tree storage tree, bytes32 key_) private {
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(tree.treeSize != 0, "AvlSegmentTree: tree is empty");

        require(tree.tree[key_].key == key_, "AvlSegmentTree: the node doesn't exist");

        function(bytes32, bytes32) pure returns (int8) comparator_ = tree.isCustomComparatorSet
            ? tree.comparator
            : _defaultComparator;

        tree.root = _removeNode(tree.tree, tree.root, key_, comparator_);

        tree.treeSize--;
    }

    function _insertNode(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32 key_,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) private returns (bytes32) {
        if (node_ == 0) {
            _tree[key_] = Node({key: key_, left: 0, right: 0, height: 1});

            return key_;
        }

        if (comparator_(key_, node_) <= 0) {
            _tree[node_].left = _insertNode(_tree, _tree[node_].left, key_, comparator_);
        } else {
            _tree[node_].right = _insertNode(_tree, _tree[node_].right, key_, comparator_);
        }

        return _balance(_tree, node_);
    }

    function _removeNode(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_,
        bytes32 key_,
        function(bytes32, bytes32) pure returns (int8) comparator_
    ) private returns (bytes32) {
        if (comparator_(key_, node_) == 0) {
            bytes32 left_ = _tree[node_].left;
            bytes32 right_ = _tree[node_].right;

            _tree[node_] = _tree[0];

            if (right_ == 0) {
                return left_;
            }

            bytes32 temp_;

            for (temp_ = right_; _tree[temp_].left != 0; temp_ = _tree[temp_].left) {}

            _tree[temp_].right = _removeMin(_tree, right_);
            _tree[temp_].left = left_;

            return _balance(_tree, temp_);
        } else if (comparator_(key_, node_) < 0) {
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
        require(key_ != 0, "AvlTree: key is not allowed to be 0");
        require(tree.treeSize != 0, "AvlTree: tree is empty");

        return tree.tree[key_].key == key_;
    }

    function _getMin(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private view returns (bytes32) {
        require(node_ != 0, "AvlTree: tree is empty");

        while (_tree[node_].left != 0) {
            node_ = _tree[node_].left;
        }

        return node_;
    }

    function _getMax(
        mapping(bytes32 => Node) storage _tree,
        bytes32 node_
    ) private view returns (bytes32) {
        require(node_ != 0, "AvlTree: tree is empty");

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
        require(tree.treeSize != 0, "AvlSegmentTreeMock: Tree is empty");

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

    function _defaultComparator(bytes32 a, bytes32 b) private pure returns (int8) {
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }
}
