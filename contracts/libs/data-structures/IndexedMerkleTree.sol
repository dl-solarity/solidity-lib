// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library IndexedMerkleTree {
    uint256 internal constant LEAVES_LEVEL = 0;
    uint64 internal constant ZERO_IDX = 0;

    bytes32 internal constant ZERO_HASH = bytes32(0);

    struct IndexedMT {
        LeafNode[] leaves;
        mapping(uint256 => bytes32[]) middleNodes;
        uint256 levelsCount;
    }

    struct LeafNode {
        bytes32 nodeHash;
        bytes32 value;
        uint256 nextLeafIndex;
    }

    error IndexOutOfBounds(uint256 index, uint256 level);
    error InvalidLowLeaf(uint256 lowLeafIndex, bytes32 newValue);

    function _init(IndexedMT storage tree) private {
        tree.leaves.push(
            LeafNode({
                nodeHash: _getZeroNodeHash(LEAVES_LEVEL),
                value: ZERO_HASH,
                nextLeafIndex: ZERO_IDX
            })
        );
        tree.levelsCount++;
    }

    function _add(IndexedMT storage tree, bytes32 value_, uint256 lowLeafIndex_) private {
        uint256 nextLeafIndex_ = _checkLowLeaf(tree, value_, lowLeafIndex_);
        uint256 newLeafIndex_ = tree.leaves.length;

        LeafNode memory newLeafNode_ = LeafNode({
            nodeHash: _hashLeaf(newLeafIndex_, value_, nextLeafIndex_, true),
            value: value_,
            nextLeafIndex: nextLeafIndex_
        });

        tree.leaves[lowLeafIndex_].nextLeafIndex = newLeafIndex_;
        _updateMerkleHashes(tree, lowLeafIndex_);

        tree.leaves.push(newLeafNode_);
        _updateLevels(tree);
        _updateMerkleHashes(tree, newLeafIndex_);
    }

    function _updateLevels(IndexedMT storage tree) private {
        uint256 currentLevel_ = LEAVES_LEVEL;
        uint256 currentLevelNodesCount_ = tree.leaves.length;

        while (currentLevelNodesCount_ > 1) {
            if (++currentLevel_ == tree.levelsCount) {
                tree.middleNodes[++tree.levelsCount].push(0);
            }

            currentLevelNodesCount_ = tree.middleNodes[currentLevel_].length;
        }
    }

    function _updateMerkleHashes(IndexedMT storage tree, uint256 leafIndex_) private {
        uint256 levelsCount_ = tree.levelsCount;

        bytes32 leftChildHash_;
        bytes32 rightChildHash_;
        uint256 currentParentIndex_ = leafIndex_;

        for (uint256 i = 0; i < levelsCount_; ++i) {
            if (i == LEAVES_LEVEL) {
                LeafNode storage leaf = tree.leaves[leafIndex_];

                bytes32 newLeafHash_ = _hashLeaf(leafIndex_, leaf.value, leaf.nextLeafIndex, true);
                leaf.nodeHash = newLeafHash_;

                bool isLeft_ = leafIndex_ % 2 == 0;
                bytes32 secondLeafHash_;

                if (isLeft_ && leafIndex_ == tree.leaves.length - 1) {
                    secondLeafHash_ = _getZeroNodeHash(LEAVES_LEVEL);
                } else if (isLeft_) {
                    secondLeafHash_ = tree.leaves[leafIndex_ + 1].nodeHash;
                } else {
                    secondLeafHash_ = tree.leaves[leafIndex_ - 1].nodeHash;
                }

                leftChildHash_ = isLeft_ ? newLeafHash_ : secondLeafHash_;
                rightChildHash_ = isLeft_ ? secondLeafHash_ : newLeafHash_;
            } else {
                currentParentIndex_ >>= 1;

                bytes32[] storage currentLevel = tree.middleNodes[i];

                bytes32 newParentHash_ = _hashNode(leftChildHash_, rightChildHash_);

                currentLevel[currentParentIndex_] = newParentHash_;

                bool isLeft_ = currentParentIndex_ % 2 == 0;
                bytes32 secondNodeHash_;

                if (isLeft_ && currentParentIndex_ == currentLevel.length - 1) {
                    secondNodeHash_ = _getZeroNodeHash(i);
                } else if (isLeft_) {
                    secondNodeHash_ = currentLevel[currentParentIndex_ + 1];
                } else {
                    secondNodeHash_ = currentLevel[currentParentIndex_ - 1];
                }
            }
        }
    }

    function _checkLowLeaf(
        IndexedMT storage tree,
        bytes32 newValue_,
        uint256 lowLeafIndex_
    ) private view returns (uint256 nextLeafIndex_) {
        LeafNode storage lowLeaf = tree.leaves[lowLeafIndex_];

        require(
            lowLeafIndex_ > 0 && lowLeafIndex_ < tree.leaves.length,
            IndexOutOfBounds(lowLeafIndex_, LEAVES_LEVEL)
        );

        nextLeafIndex_ = lowLeaf.nextLeafIndex;

        require(
            lowLeaf.value < newValue_ &&
                (nextLeafIndex_ == ZERO_IDX || tree.leaves[nextLeafIndex_].value > newValue_),
            InvalidLowLeaf(lowLeafIndex_, newValue_)
        );
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
