// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library IndexedMerkleTree {
    struct UintIndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(UintIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function setHashers(UintIndexedMT storage tree, HashFunctions memory hashFunctions_) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    function add(
        UintIndexedMT storage tree,
        uint256 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(value_), lowLeafIndex_);
    }

    function update(
        UintIndexedMT storage tree,
        uint256 leafIndex_,
        uint256 currentLowLeafIndex_,
        uint256 newValue_,
        uint256 newLowLeafIndex_
    ) internal {
        _update(
            tree._indexedMT,
            leafIndex_,
            currentLowLeafIndex_,
            bytes32(newValue_),
            newLowLeafIndex_
        );
    }

    function getProof(
        UintIndexedMT storage tree,
        uint256 index_,
        uint256 value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, bytes32(value_));
    }

    function verifyProof(
        UintIndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    function processProof(Proof memory proof_) internal view returns (bytes32) {
        return _processProof(proof_, HashFunctions({hash2: _hash2, hash4: _hash4}));
    }

    function processProof(
        Proof memory proof_,
        HashFunctions memory hashFunctions_
    ) internal view returns (bytes32) {
        return _processProof(proof_, hashFunctions_);
    }

    function getRoot(UintIndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    function getTreeLevels(UintIndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    function getLeafData(
        UintIndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    function getNodeHash(
        UintIndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    function getLeavesCount(UintIndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    function getLevelNodesCount(
        UintIndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    function isCustomHasherSet(UintIndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    struct Bytes32IndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(Bytes32IndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function setHashers(
        Bytes32IndexedMT storage tree,
        HashFunctions memory hashFunctions_
    ) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    function add(
        Bytes32IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, value_, lowLeafIndex_);
    }

    function update(
        Bytes32IndexedMT storage tree,
        uint256 leafIndex_,
        uint256 currentLowLeafIndex_,
        bytes32 newValue_,
        uint256 newLowLeafIndex_
    ) internal {
        _update(tree._indexedMT, leafIndex_, currentLowLeafIndex_, newValue_, newLowLeafIndex_);
    }

    function getProof(
        Bytes32IndexedMT storage tree,
        uint256 index_,
        bytes32 value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, value_);
    }

    function verifyProof(
        Bytes32IndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    function getRoot(Bytes32IndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    function getTreeLevels(Bytes32IndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    function getLeafData(
        Bytes32IndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    function getNodeHash(
        Bytes32IndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    function getLeavesCount(Bytes32IndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    function getLevelNodesCount(
        Bytes32IndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    function isCustomHasherSet(Bytes32IndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    struct AddressIndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(AddressIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function setHashers(
        AddressIndexedMT storage tree,
        HashFunctions memory hashFunctions_
    ) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    function add(
        AddressIndexedMT storage tree,
        address value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(uint256(uint160(value_))), lowLeafIndex_);
    }

    function update(
        AddressIndexedMT storage tree,
        uint256 leafIndex_,
        uint256 currentLowLeafIndex_,
        address newValue_,
        uint256 newLowLeafIndex_
    ) internal {
        _update(
            tree._indexedMT,
            leafIndex_,
            currentLowLeafIndex_,
            bytes32(uint256(uint160(newValue_))),
            newLowLeafIndex_
        );
    }

    function getProof(
        AddressIndexedMT storage tree,
        uint256 index_,
        address value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, bytes32(uint256(uint160(value_))));
    }

    function verifyProof(
        AddressIndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    function getRoot(AddressIndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    function getTreeLevels(AddressIndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    function getLeafData(
        AddressIndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    function getNodeHash(
        AddressIndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    function getLeavesCount(AddressIndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    function getLevelNodesCount(
        AddressIndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    function isCustomHasherSet(AddressIndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    uint256 internal constant LEAVES_LEVEL = 0;
    uint64 internal constant ZERO_IDX = 0;

    bytes32 internal constant ZERO_HASH = bytes32(0);

    struct IndexedMT {
        LeafData[] leavesData;
        mapping(uint256 level => bytes32[] nodeHashes) nodes;
        uint256 levelsCount;
        bool isCustomHasherSet;
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32, bytes32) view returns (bytes32) hash4;
    }

    struct HashFunctions {
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32, bytes32) view returns (bytes32) hash4;
    }

    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        bool existence;
        uint256 index;
        bytes32 value;
        uint256 nextLeafIndex;
    }

    struct LeafData {
        bytes32 value;
        uint256 nextLeafIndex;
    }

    error ZeroLeafIndex();
    error IndexOutOfBounds(uint256 index, uint256 level);
    error InvalidLowLeaf(uint256 lowLeafIndex, bytes32 newValue);
    error InvalidProofIndex(uint256 index, bytes32 value);
    error NotANodeLevel();
    error NotALowLeafIndex(uint256 leafIndex, uint256 lowLeafIndex);
    error IndexedMerkleTreeNotInitialized();
    error IndexedMerkleTreeAlreadyInitialized();

    modifier onlyInitialized(IndexedMT storage tree) {
        if (!_isInitialized(tree)) revert IndexedMerkleTreeNotInitialized();
        _;
    }

    function _initialize(IndexedMT storage tree) private {
        if (_isInitialized(tree)) revert IndexedMerkleTreeAlreadyInitialized();

        tree.leavesData.push(LeafData({value: ZERO_HASH, nextLeafIndex: ZERO_IDX}));
        tree.nodes[LEAVES_LEVEL].push(_hashLeaf(0, 0, 0, true, _getHashFunctions(tree).hash4));

        tree.levelsCount++;
    }

    function _setHashers(IndexedMT storage tree, HashFunctions memory hashFunctions_) private {
        if (_isInitialized(tree)) revert IndexedMerkleTreeAlreadyInitialized();

        tree.isCustomHasherSet = true;

        tree.hash2 = hashFunctions_.hash2;
        tree.hash4 = hashFunctions_.hash4;
    }

    function _add(
        IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) private onlyInitialized(tree) returns (uint256) {
        uint256 nextLeafIndex_ = _checkLowLeaf(tree, value_, lowLeafIndex_);
        uint256 newLeafIndex_ = _getLeavesCount(tree);

        _updateNextLeafIndex(tree, lowLeafIndex_, newLeafIndex_);

        LeafData memory newLeafData_ = LeafData({value: value_, nextLeafIndex: nextLeafIndex_});

        _pushLeaf(tree, newLeafIndex_, newLeafData_);

        return newLeafIndex_;
    }

    function _update(
        IndexedMT storage tree,
        uint256 leafIndex_,
        uint256 currentLowLeafIndex_,
        bytes32 newValue_,
        uint256 newLowLeafIndex_
    ) private onlyInitialized(tree) {
        require(leafIndex_ != ZERO_IDX, ZeroLeafIndex());
        require(
            _getLeafNextIndex(tree, currentLowLeafIndex_) == leafIndex_,
            NotALowLeafIndex(leafIndex_, currentLowLeafIndex_)
        );

        tree.leavesData[leafIndex_].value = newValue_;

        if (newLowLeafIndex_ != currentLowLeafIndex_ && newLowLeafIndex_ != leafIndex_) {
            uint256 newNextLeafIndex_ = _checkLowLeaf(tree, newValue_, newLowLeafIndex_);

            _updateNextLeafIndex(tree, currentLowLeafIndex_, _getLeafNextIndex(tree, leafIndex_));
            _updateNextLeafIndex(tree, newLowLeafIndex_, leafIndex_);
            _updateNextLeafIndex(tree, leafIndex_, newNextLeafIndex_);
        } else {
            _updateMerkleHashes(tree, leafIndex_);
        }
    }

    function _pushLeaf(
        IndexedMT storage tree,
        uint256 leafIndex_,
        LeafData memory leafData_
    ) private {
        tree.leavesData.push(leafData_);

        uint256 levelsCount_ = tree.levelsCount;
        uint256 levelIndex_ = leafIndex_;

        HashFunctions memory hashFunctions_ = _getHashFunctions(tree);

        for (uint256 i = 0; i < levelsCount_; i++) {
            bytes32 currentLevelNodeHash_;

            if (i == LEAVES_LEVEL) {
                currentLevelNodeHash_ = _hashLeaf(
                    levelIndex_,
                    leafData_.value,
                    leafData_.nextLeafIndex,
                    true,
                    hashFunctions_.hash4
                );
            } else {
                currentLevelNodeHash_ = _calculateNodeHash(tree, levelIndex_, i, hashFunctions_);
            }

            if (levelIndex_ == _getLevelNodesCount(tree, i)) {
                tree.nodes[i].push(currentLevelNodeHash_);
            } else {
                tree.nodes[i][levelIndex_] = currentLevelNodeHash_;
            }

            if (i + 1 == levelsCount_ && _getLevelNodesCount(tree, i) > 1) {
                levelsCount_++;
            }

            levelIndex_ /= 2;
        }

        tree.levelsCount = levelsCount_;
    }

    function _updateNextLeafIndex(
        IndexedMT storage tree,
        uint256 leafIndex_,
        uint256 newNextLeafIndex_
    ) private {
        tree.leavesData[leafIndex_].nextLeafIndex = newNextLeafIndex_;

        _updateMerkleHashes(tree, leafIndex_);
    }

    function _updateMerkleHashes(IndexedMT storage tree, uint256 leafIndex_) private {
        uint256 levelsCount_ = tree.levelsCount;
        uint256 levelIndex_ = leafIndex_;

        HashFunctions memory hashFunctions_ = _getHashFunctions(tree);

        for (uint256 i = 0; i < levelsCount_; i++) {
            bytes32 currentLevelNodeHash_;

            if (i == LEAVES_LEVEL) {
                LeafData memory leafData_ = _getLeafData(tree, levelIndex_);

                currentLevelNodeHash_ = _hashLeaf(
                    levelIndex_,
                    leafData_.value,
                    leafData_.nextLeafIndex,
                    true,
                    hashFunctions_.hash4
                );
            } else {
                currentLevelNodeHash_ = _calculateNodeHash(tree, levelIndex_, i, hashFunctions_);
            }

            tree.nodes[i][levelIndex_] = currentLevelNodeHash_;

            levelIndex_ /= 2;
        }
    }

    function _proof(
        IndexedMT storage tree,
        uint256 index_,
        bytes32 value_
    ) private view returns (Proof memory) {
        LeafData memory leafData_ = _getLeafData(tree, index_);

        Proof memory proof_ = Proof({
            root: _getRoot(tree),
            siblings: new bytes32[](tree.levelsCount - 1),
            existence: false,
            index: index_,
            value: leafData_.value,
            nextLeafIndex: leafData_.nextLeafIndex
        });

        if (leafData_.value == value_) {
            proof_.existence = true;
        } else if (!_isLowLeaf(tree, value_, index_)) {
            revert InvalidProofIndex(index_, value_);
        }

        HashFunctions memory hashFunctions_ = _getHashFunctions(tree);

        uint256 parentIndex_ = index_;

        for (uint256 i = 0; i < proof_.siblings.length; ++i) {
            uint256 currentLevelIndex_ = parentIndex_ % 2 == 0
                ? parentIndex_ + 1
                : parentIndex_ - 1;

            proof_.siblings[i] = currentLevelIndex_ < _getLevelNodesCount(tree, i)
                ? tree.nodes[i][currentLevelIndex_]
                : _getZeroNodeHash(i, hashFunctions_);

            parentIndex_ /= 2;
        }

        return proof_;
    }

    function _verifyProof(
        IndexedMT storage tree,
        Proof memory proof_
    ) private view returns (bool) {
        return _processProof(proof_, _getHashFunctions(tree)) == _getRoot(tree);
    }

    function _processProof(
        Proof memory proof_,
        HashFunctions memory hashFunctions_
    ) private view returns (bytes32) {
        bytes32 computedHash_ = _hashLeaf(
            proof_.index,
            proof_.value,
            proof_.nextLeafIndex,
            true,
            hashFunctions_.hash4
        );

        for (uint256 i = 0; i < proof_.siblings.length; ++i) {
            if ((proof_.index >> i) & 1 == 1) {
                computedHash_ = _hashNode(proof_.siblings[i], computedHash_, hashFunctions_.hash2);
            } else {
                computedHash_ = _hashNode(computedHash_, proof_.siblings[i], hashFunctions_.hash2);
            }
        }

        return computedHash_;
    }

    function _getRoot(IndexedMT storage tree) private view returns (bytes32) {
        return tree.nodes[tree.levelsCount - 1][0];
    }

    function _getTreeLevels(IndexedMT storage tree) private view returns (uint256) {
        return tree.levelsCount;
    }

    function _getLeavesCount(IndexedMT storage tree) private view returns (uint256) {
        return _getLevelNodesCount(tree, LEAVES_LEVEL);
    }

    function _getLevelNodesCount(
        IndexedMT storage tree,
        uint256 level_
    ) private view returns (uint256) {
        return tree.nodes[level_].length;
    }

    function _getNodeHash(
        IndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) private view returns (bytes32) {
        return tree.nodes[level_][index_];
    }

    function _getLeafData(
        IndexedMT storage tree,
        uint256 index_
    ) private view returns (LeafData memory) {
        _checkIndexExistence(tree, index_, LEAVES_LEVEL);

        return tree.leavesData[index_];
    }

    function _getLeafNextIndex(
        IndexedMT storage tree,
        uint256 index_
    ) private view returns (uint256) {
        _checkIndexExistence(tree, index_, LEAVES_LEVEL);

        return tree.leavesData[index_].nextLeafIndex;
    }

    function _calculateNodeHash(
        IndexedMT storage tree,
        uint256 index_,
        uint256 level_,
        HashFunctions memory hashFunctions_
    ) private view returns (bytes32) {
        uint256 childrenLevel_ = level_ - 1;
        uint256 leftChild_ = index_ * 2;
        uint256 rightChild_ = index_ * 2 + 1;

        bytes32 leftChildHash_ = _getNodeHash(tree, leftChild_, childrenLevel_);
        bytes32 rightChildHash_ = rightChild_ < _getLevelNodesCount(tree, childrenLevel_)
            ? _getNodeHash(tree, rightChild_, childrenLevel_)
            : _getZeroNodeHash(childrenLevel_, hashFunctions_);

        return _hashNode(leftChildHash_, rightChildHash_, hashFunctions_.hash2);
    }

    function _checkIndexExistence(
        IndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) private view {
        if (index_ >= tree.nodes[level_].length) {
            revert IndexOutOfBounds(index_, level_);
        }
    }

    function _checkLowLeaf(
        IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) private view returns (uint256) {
        if (!_isLowLeaf(tree, value_, lowLeafIndex_)) {
            revert InvalidLowLeaf(lowLeafIndex_, value_);
        }

        return _getLeafData(tree, lowLeafIndex_).nextLeafIndex;
    }

    function _isLowLeaf(
        IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) private view returns (bool) {
        LeafData memory lowLeafData = _getLeafData(tree, lowLeafIndex_);

        uint256 nextLeafIndex_ = lowLeafData.nextLeafIndex;

        return
            lowLeafData.value < value_ &&
            (nextLeafIndex_ == ZERO_IDX || _getLeafData(tree, nextLeafIndex_).value > value_);
    }

    function _isInitialized(IndexedMT storage tree) private view returns (bool) {
        return tree.levelsCount > 0;
    }

    function _isCustomHasherSet(IndexedMT storage tree) private view returns (bool) {
        return tree.isCustomHasherSet;
    }

    function _getZeroNodeHash(
        uint256 level_,
        HashFunctions memory hashFunctions_
    ) private view returns (bytes32) {
        if (level_ == 0) {
            return _hashLeaf(0, 0, 0, false, hashFunctions_.hash4);
        }

        bytes32 prevLevelNodeHash_ = _getZeroNodeHash(level_ - 1, hashFunctions_);

        return _hashNode(prevLevelNodeHash_, prevLevelNodeHash_, hashFunctions_.hash2);
    }

    function _hashNode(
        bytes32 leftChildHash_,
        bytes32 rightChildHash_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) private view returns (bytes32) {
        return hash2_(leftChildHash_, rightChildHash_);
    }

    function _hashLeaf(
        uint256 leafIndex_,
        bytes32 value_,
        uint256 nextLeafIndex_,
        bool isActive_,
        function(bytes32, bytes32, bytes32, bytes32) view returns (bytes32) hash4_
    ) private view returns (bytes32) {
        return
            hash4_(
                bytes32(uint256(isActive_ ? 1 : 0)),
                bytes32(leafIndex_),
                value_,
                bytes32(nextLeafIndex_)
            );
    }

    function _getHashFunctions(
        IndexedMT storage tree
    ) private view returns (HashFunctions memory) {
        return
            HashFunctions({
                hash2: tree.isCustomHasherSet ? tree.hash2 : _hash2,
                hash4: tree.isCustomHasherSet ? tree.hash4 : _hash4
            });
    }

    function _hash2(bytes32 a_, bytes32 b_) private pure returns (bytes32 result_) {
        assembly {
            mstore(0, a_)
            mstore(32, b_)

            result_ := keccak256(0, 64)
        }
    }

    /**
     * @dev The decision not to update the free memory pointer is due to the temporary nature of the hash arguments.
     */
    function _hash4(
        bytes32 a_,
        bytes32 b_,
        bytes32 c_,
        bytes32 d_
    ) private pure returns (bytes32 result_) {
        assembly {
            let freePtr_ := mload(64)

            mstore(freePtr_, a_)
            mstore(add(freePtr_, 32), b_)
            mstore(add(freePtr_, 64), c_)
            mstore(add(freePtr_, 96), d_)

            result_ := keccak256(freePtr_, 128)
        }
    }
}
