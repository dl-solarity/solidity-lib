// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Traversal, AvlTree} from "../../../libs/data-structures/AvlTree.sol";

contract AvlTreeMock {
    using AvlTree for *;
    using Traversal for *;

    AvlTree.UintAVL internal _uintTree;
    AvlTree.Bytes32AVL internal _bytes32Tree;
    AvlTree.AddressAVL internal _addressTree;

    function setUintDescComparator() external {
        _uintTree.setComparator(_descComparator);
    }

    function setBytes32DescComparator() external {
        _bytes32Tree.setComparator(_descComparator);
    }

    function setAddressDescComparator() external {
        _addressTree.setComparator(_descComparator);
    }

    function insertUint(uint256 key_, uint256 value_) external {
        _uintTree.insert(bytes32(key_), value_);
    }

    function insertBytes32(uint256 key_, bytes32 value_) external {
        _bytes32Tree.insert(bytes32(key_), value_);
    }

    function insertAddress(uint256 key_, address value_) external {
        _addressTree.insert(bytes32(key_), value_);
    }

    function removeUint(uint256 key_) external {
        _uintTree.remove(bytes32(key_));
    }

    function removeBytes32(uint256 key_) external {
        _bytes32Tree.remove(bytes32(key_));
    }

    function removeAddress(uint256 key_) external {
        _addressTree.remove(bytes32(key_));
    }

    function getUint(uint256 key_) external view returns (uint256) {
        return _uintTree.get(bytes32(key_));
    }

    function getBytes32(uint256 key_) external view returns (bytes32) {
        return _bytes32Tree.get(bytes32(key_));
    }

    function getAddressValue(uint256 key_) external view returns (address) {
        return _addressTree.get(bytes32(key_));
    }

    function tryGetUint(uint256 key_) external view returns (bool, uint256) {
        return _uintTree.tryGet(bytes32(key_));
    }

    function tryGetBytes32(uint256 key_) external view returns (bool, bytes32) {
        return _bytes32Tree.tryGet(bytes32(key_));
    }

    function tryGetAddress(uint256 key_) external view returns (bool, address) {
        return _addressTree.tryGet(bytes32(key_));
    }

    function sizeUint() external view returns (uint64) {
        return _uintTree.size();
    }

    function sizeBytes32() external view returns (uint64) {
        return _bytes32Tree.size();
    }

    function sizeAddress() external view returns (uint64) {
        return _addressTree.size();
    }

    function rootUint() external view returns (uint256) {
        return uint256(_uintTree._tree.tree[_uintTree._tree.root].key);
    }

    function rootBytes32() external view returns (uint256) {
        return uint256(_bytes32Tree._tree.tree[_bytes32Tree._tree.root].key);
    }

    function rootAddress() external view returns (uint256) {
        return uint256(_addressTree._tree.tree[_addressTree._tree.root].key);
    }

    function traverseUint() external view returns (uint256[] memory, uint256[] memory) {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        uint256[] memory keys_ = new uint256[](_uintTree.size());
        uint256[] memory values_ = new uint256[](_uintTree.size());

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = uint256(bytesValue_);
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = uint256(bytesValue_);

            index_++;
        }

        return (keys_, values_);
    }

    function traverseFirstThreeUint() external view returns (uint256[] memory, uint256[] memory) {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        uint256[] memory keys_ = new uint256[](3);
        uint256[] memory values_ = new uint256[](3);

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = uint256(bytesValue_);
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = uint256(bytesValue_);

            if (index_++ == 2) {
                iterator_ = _uintTree.last();
            }
        }

        return (keys_, values_);
    }

    function brokenTraversalUint() external view {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        uint256[] memory keys_ = new uint256[](_uintTree.size());
        uint256[] memory values_ = new uint256[](_uintTree.size());

        (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

        keys_[0] = uint256(bytesKey_);
        values_[0] = uint256(bytesValue_);

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            iterator_.currentNode = 0;

            (bytesKey_, bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = uint256(bytesValue_);
        }
    }

    function backwardsTraversalUint() external view returns (uint256[] memory, uint256[] memory) {
        Traversal.Iterator memory iterator_ = _uintTree.last();

        uint256[] memory keys_ = new uint256[](_uintTree.size());
        uint256[] memory values_ = new uint256[](_uintTree.size());

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = uint256(bytesValue_);
        }

        uint256 index_ = 1;

        while (iterator_.hasPrev()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.prev();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = uint256(bytesValue_);

            index_++;
        }

        return (keys_, values_);
    }

    function traverseBytes32() external view returns (uint256[] memory, bytes32[] memory) {
        Traversal.Iterator memory iterator_ = _bytes32Tree.first();

        uint256[] memory keys_ = new uint256[](_bytes32Tree.size());
        bytes32[] memory values_ = new bytes32[](_bytes32Tree.size());

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = bytesValue_;
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = bytesValue_;

            index_++;
        }

        return (keys_, values_);
    }

    function traverseFirstThreeBytes32()
        external
        view
        returns (uint256[] memory, bytes32[] memory)
    {
        Traversal.Iterator memory iterator_ = _bytes32Tree.first();

        uint256[] memory keys_ = new uint256[](3);
        bytes32[] memory values_ = new bytes32[](3);

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = bytesValue_;
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = bytesValue_;

            if (index_++ == 2) {
                iterator_ = _bytes32Tree.last();
            }
        }

        return (keys_, values_);
    }

    function traverseAddress() external view returns (uint256[] memory, address[] memory) {
        Traversal.Iterator memory iterator_ = _addressTree.first();

        uint256[] memory keys_ = new uint256[](_addressTree.size());
        address[] memory values_ = new address[](_addressTree.size());

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = address(uint160(uint256(bytesValue_)));
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = address(uint160(uint256(bytesValue_)));

            index_++;
        }

        return (keys_, values_);
    }

    function traverseFirstThreeAddress()
        external
        view
        returns (uint256[] memory, address[] memory)
    {
        Traversal.Iterator memory iterator_ = _addressTree.first();

        uint256[] memory keys_ = new uint256[](3);
        address[] memory values_ = new address[](3);

        if (keys_.length != 0) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[0] = uint256(bytesKey_);
            values_[0] = address(uint160(uint256(bytesValue_)));
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.next();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = address(uint160(uint256(bytesValue_)));

            if (index_++ == 2) {
                iterator_ = _addressTree.last();
            }
        }

        return (keys_, values_);
    }

    function isCustomComparatorSetUint() external view returns (bool) {
        return _uintTree.isCustomComparatorSet();
    }

    function isCustomComparatorSetBytes32() external view returns (bool) {
        return _bytes32Tree.isCustomComparatorSet();
    }

    function isCustomComparatorSetAddress() external view returns (bool) {
        return _addressTree.isCustomComparatorSet();
    }

    function _descComparator(bytes32 key1_, bytes32 key2_) private pure returns (int256) {
        if (key1_ > key2_) {
            return -1;
        }

        if (key1_ < key2_) {
            return 1;
        }

        return 0;
    }
}
