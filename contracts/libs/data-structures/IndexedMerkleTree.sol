// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library IndexedMerkleTree {
    struct UintIndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(UintIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function add(
        UintIndexedMT storage tree,
        uint256 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(value_), lowLeafIndex_);
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

    function processProof(Proof memory proof_) internal pure returns (bytes32) {
        return _processProof(proof_);
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

    struct Bytes32IndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(Bytes32IndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function add(
        Bytes32IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, value_, lowLeafIndex_);
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

    struct AddressIndexedMT {
        IndexedMT _indexedMT;
    }

    function initialize(AddressIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    function add(
        AddressIndexedMT storage tree,
        address value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(uint256(uint160(value_))), lowLeafIndex_);
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

    uint256 internal constant LEAVES_LEVEL = 0;
    uint64 internal constant ZERO_IDX = 0;

    bytes32 internal constant ZERO_HASH = bytes32(0);

    struct IndexedMT {
        LeafData[] leavesData;
        mapping(uint256 level => bytes32[] nodeHashes) nodes;
        uint256 levelsCount;
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

    error IndexOutOfBounds(uint256 index, uint256 level);
    error InvalidLowLeaf(uint256 lowLeafIndex, bytes32 newValue);
    error InvalidProofIndex(uint256 index, bytes32 value);
    error NotANodeLevel();
    error IndexedMerkleTreeNotInitialized();
    error IndexedMerkleTreeAlreadyInitialized();

    modifier onlyInitialized(IndexedMT storage tree) {
        if (!_isInitialized(tree)) revert IndexedMerkleTreeNotInitialized();
        _;
    }

    function _initialize(IndexedMT storage tree) private {
        if (_isInitialized(tree)) revert IndexedMerkleTreeAlreadyInitialized();

        tree.leavesData.push(LeafData({value: ZERO_HASH, nextLeafIndex: ZERO_IDX}));
        tree.nodes[LEAVES_LEVEL].push(_hashLeaf(0, 0, 0, true));

        tree.levelsCount++;
    }

    function _add(
        IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) private onlyInitialized(tree) returns (uint256) {
        uint256 nextLeafIndex_ = _checkLowLeaf(tree, value_, lowLeafIndex_);
        uint256 newLeafIndex_ = _getLeavesCount(tree);

        tree.leavesData[lowLeafIndex_].nextLeafIndex = newLeafIndex_;
        _updateMerkleHashes(tree, lowLeafIndex_);

        LeafData memory newLeafData_ = LeafData({value: value_, nextLeafIndex: nextLeafIndex_});

        _pushLeaf(tree, newLeafIndex_, newLeafData_);

        return newLeafIndex_;
    }

    function _pushLeaf(
        IndexedMT storage tree,
        uint256 leafIndex_,
        LeafData memory leafData_
    ) private {
        tree.leavesData.push(leafData_);

        uint256 levelsCount_ = tree.levelsCount;
        uint256 levelIndex_ = leafIndex_;

        for (uint256 i = 0; i < levelsCount_; i++) {
            bytes32 currentLevelNodeHash_;

            if (i == LEAVES_LEVEL) {
                currentLevelNodeHash_ = _hashLeaf(
                    levelIndex_,
                    leafData_.value,
                    leafData_.nextLeafIndex,
                    true
                );
            } else {
                currentLevelNodeHash_ = _calculateNodeHash(tree, levelIndex_, i);
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

    function _updateMerkleHashes(IndexedMT storage tree, uint256 leafIndex_) private {
        uint256 levelsCount_ = tree.levelsCount;
        uint256 levelIndex_ = leafIndex_;

        for (uint256 i = 0; i < levelsCount_; i++) {
            bytes32 currentLevelNodeHash_;

            if (i == LEAVES_LEVEL) {
                LeafData memory leafData_ = _getLeafData(tree, levelIndex_);

                currentLevelNodeHash_ = _hashLeaf(
                    levelIndex_,
                    leafData_.value,
                    leafData_.nextLeafIndex,
                    true
                );
            } else {
                currentLevelNodeHash_ = _calculateNodeHash(tree, levelIndex_, i);
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

        uint256 parentIndex_ = index_;

        for (uint256 i = 0; i < proof_.siblings.length; ++i) {
            uint256 currentLevelIndex_ = parentIndex_ % 2 == 0
                ? parentIndex_ + 1
                : parentIndex_ - 1;

            proof_.siblings[i] = currentLevelIndex_ < _getLevelNodesCount(tree, i)
                ? tree.nodes[i][currentLevelIndex_]
                : _getZeroNodeHash(i);

            parentIndex_ /= 2;
        }

        return proof_;
    }

    function _verifyProof(
        IndexedMT storage tree,
        Proof memory proof_
    ) private view returns (bool) {
        return _processProof(proof_) == _getRoot(tree);
    }

    function _processProof(Proof memory proof_) private pure returns (bytes32) {
        bytes32 computedHash_ = _hashLeaf(proof_.index, proof_.value, proof_.nextLeafIndex, true);

        for (uint256 i = 0; i < proof_.siblings.length; ++i) {
            if ((proof_.index >> i) & 1 == 1) {
                computedHash_ = _hashNode(proof_.siblings[i], computedHash_);
            } else {
                computedHash_ = _hashNode(computedHash_, proof_.siblings[i]);
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

    function _calculateNodeHash(
        IndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) private view returns (bytes32) {
        uint256 childrenLevel_ = level_ - 1;
        uint256 leftChild_ = index_ * 2;
        uint256 rightChild_ = index_ * 2 + 1;

        bytes32 leftChildHash_ = _getNodeHash(tree, leftChild_, childrenLevel_);
        bytes32 rightChildHash_ = rightChild_ < _getLevelNodesCount(tree, childrenLevel_)
            ? _getNodeHash(tree, rightChild_, childrenLevel_)
            : _getZeroNodeHash(childrenLevel_);

        return _hashNode(leftChildHash_, rightChildHash_);
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

    function _getZeroNodeHash(uint256 level_) private pure returns (bytes32) {
        if (level_ == 0) {
            return _hashLeaf(0, 0, 0, false);
        }

        bytes32 prevLevelNodeHash_ = _getZeroNodeHash(level_ - 1);

        return _hashNode(prevLevelNodeHash_, prevLevelNodeHash_);
    }

    function _hashNode(
        bytes32 leftChildHash_,
        bytes32 rightChildHash_
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(leftChildHash_, rightChildHash_));
    }

    function _hashLeaf(
        uint256 leafIndex_,
        bytes32 value_,
        uint256 nextLeafIndex_,
        bool isActive_
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(isActive_, leafIndex_, value_, nextLeafIndex_));
    }
}
