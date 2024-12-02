// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

library CartesianMerkleTree {
    /**
     ************************
     *       InnerCMT       *
     ************************
     */

    struct CMT {
        mapping(uint64 => Node) nodes;
        uint64 merkleRootId;
        uint64 nodesCount;
        uint64 deletedNodesCount;
        uint32 desiredProofSize;
        bool isCustomHasherSet;
        function(bytes32) view returns (bytes32) hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2;
    }

    struct Node {
        uint64 childLeft;
        uint64 childRight;
        bytes16 priority;
        bytes32 merkleHash;
        bytes32 key;
    }

    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        bool existence;
        bytes32 key;
        bytes32 nonExistenceKey;
    }

    bytes32 internal constant ZERO_HASH = bytes32(0);

    modifier onlyInitialized(CMT storage treap) {
        require(_isInitialized(treap), "CartesianMerkleTree: treap is not initialized");
        _;
    }

    function _initialize(CMT storage treap, uint32 desiredProofSize_) private {
        require(!_isInitialized(treap), "CartesianMerkleTree: treap is already initialized");

        _setDesiredProofSize(treap, desiredProofSize_);
    }

    function _setDesiredProofSize(CMT storage treap, uint32 desiredProofSize_) private {
        require(
            desiredProofSize_ > 0,
            "CartesianMerkleTree: desired proof size must be greater than zero"
        );

        treap.desiredProofSize = desiredProofSize_;
    }

    function _setHashers(
        CMT storage treap,
        function(bytes32) view returns (bytes32) hash1_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) private {
        require(_nodesCount(treap) == 0, "CartesianMerkleTree: treap is not empty");

        treap.isCustomHasherSet = true;

        treap.hash1 = hash1_;
        treap.hash2 = hash2_;
    }

    function insert(CMT storage treap, bytes32 key_, bytes16 value_) internal {
        Node memory node_ = Node({
            childLeft: 0,
            childRight: 0,
            merkleHash: key_,
            key: key_,
            // priority: bytes16(_getPriorityHash(treap, key_))
            priority: value_
        });

        uint64 nodeId_ = ++treap.nodesCount;

        treap.nodes[nodeId_] = node_;

        if (treap.merkleRootId == 0) {
            treap.merkleRootId = nodeId_;

            return;
        }

        (uint256 left_, uint256 right_) = _split(treap, treap.merkleRootId, key_);
        treap.merkleRootId = uint64(_merge(treap, _merge(treap, left_, nodeId_), right_));
    }

    function remove(CMT storage treap, bytes32 key_) internal {
        if (treap.merkleRootId == 0) {
            return;
        }

        (uint256 left_, uint256 tmp_) = _split(treap, treap.merkleRootId, key_);
        (uint256 toRemove_, uint256 right_) = _split(treap, tmp_, bytes32(uint256(key_) + 1));

        treap.merkleRootId = uint64(_merge(treap, left_, right_));

        delete treap.nodes[uint64(toRemove_)];
    }

    function proof(
        CMT storage treap,
        bytes32 key_,
        uint256 desiredProofSize_
    ) internal view returns (Proof memory) {
        desiredProofSize_ = desiredProofSize_ == 0 ? _desiredProofSize(treap) : desiredProofSize_;

        Proof memory proof_ = Proof({
            root: _root(treap),
            siblings: new bytes32[](desiredProofSize_),
            existence: false,
            key: key_,
            nonExistenceKey: ZERO_HASH
        });

        Node memory node_;
        uint256 currentSiblingsIndex_;
        uint256 nextNodeId_ = treap.merkleRootId;

        while (true) {
            node_ = treap.nodes[uint64(nextNodeId_)];

            if (node_.key == key_) {
                bytes32 childrenHash_ = _hashNodes(
                    treap,
                    treap.nodes[node_.childLeft],
                    treap.nodes[node_.childRight]
                );

                if (childrenHash_ != 0) {
                    _addProofSibling(proof_, currentSiblingsIndex_++, childrenHash_);
                }

                _addProofSibling(proof_, currentSiblingsIndex_++, key_);

                proof_.existence = true;

                break;
            }

            _addProofSibling(proof_, currentSiblingsIndex_++, node_.key);

            uint64 otherNodeId_;

            if (node_.key > key_) {
                otherNodeId_ = node_.childRight;
                nextNodeId_ = node_.childLeft;
            } else {
                otherNodeId_ = node_.childLeft;
                nextNodeId_ = node_.childRight;
            }

            if (nextNodeId_ == 0) {
                _addProofSibling(proof_, currentSiblingsIndex_++, key_);
                proof_.nonExistenceKey = node_.key;

                break;
            }

            _addProofSibling(
                proof_,
                currentSiblingsIndex_++,
                treap.nodes[otherNodeId_].merkleHash
            );
        }

        return proof_;
    }

    function _split(
        CMT storage treap,
        uint256 nodeId_,
        bytes32 key_
    ) private returns (uint256 leftNodeId_, uint256 rightNodeId_) {
        Node storage node_ = treap.nodes[uint64(nodeId_)];

        if (node_.key == 0) {
            return (0, 0);
        }

        if (node_.key < key_) {
            (uint256 leftSplit_, uint256 rightSplit_) = _split(treap, node_.childRight, key_);

            node_.childRight = uint64(leftSplit_);

            (leftNodeId_, rightNodeId_) = (nodeId_, rightSplit_);
        } else {
            (uint256 leftSplit_, uint256 rightSplit_) = _split(treap, node_.childLeft, key_);

            node_.childLeft = uint64(rightSplit_);

            (leftNodeId_, rightNodeId_) = (leftSplit_, nodeId_);
        }

        _updateNodeMerkleHash(treap, nodeId_);

        return (leftNodeId_, rightNodeId_);
    }

    function _merge(
        CMT storage treap,
        uint256 leftNodeId_,
        uint256 rightNodeId_
    ) private returns (uint256 nodeId_) {
        Node storage leftNode_ = treap.nodes[uint64(leftNodeId_)];

        if (leftNode_.key == 0) {
            return rightNodeId_;
        }

        Node storage rightNode_ = treap.nodes[uint64(rightNodeId_)];

        if (rightNode_.key == 0) {
            return leftNodeId_;
        }

        if (leftNode_.priority > rightNode_.priority) {
            leftNode_.childRight = uint64(_merge(treap, leftNode_.childRight, rightNodeId_));

            nodeId_ = leftNodeId_;
        } else {
            rightNode_.childLeft = uint64(_merge(treap, leftNodeId_, rightNode_.childLeft));

            nodeId_ = rightNodeId_;
        }

        _updateNodeMerkleHash(treap, nodeId_);

        return nodeId_;
    }

    function _updateNodeMerkleHash(CMT storage treap, uint256 nodeId_) private {
        Node storage node_ = treap.nodes[uint64(nodeId_)];

        bytes32 childrenHash_ = _hashNodes(
            treap,
            treap.nodes[node_.childLeft],
            treap.nodes[node_.childRight]
        );

        node_.merkleHash = childrenHash_ == ZERO_HASH
            ? node_.key
            : _hash2(childrenHash_, node_.key);
    }

    function _addProofSibling(
        Proof memory proof_,
        uint256 currentSiblingsIndex_,
        bytes32 siblingToAdd_
    ) private pure {
        require(
            currentSiblingsIndex_ < proof_.siblings.length,
            "CartesianMerkleTree: desired proof size is too low"
        );

        proof_.siblings[currentSiblingsIndex_] = siblingToAdd_;
    }

    function _hashNodes(
        CMT storage treap,
        Node storage leftNode_,
        Node storage rightNode_
    ) private view returns (bytes32) {
        bytes32 left_;
        bytes32 right_;

        if (leftNode_.key != 0) {
            left_ = leftNode_.merkleHash;
        }

        if (rightNode_.key != 0) {
            right_ = rightNode_.merkleHash;
        }

        if (left_ > right_) {
            (left_, right_) = (right_, left_);
        }

        return left_ == 0 && right_ == 0 ? ZERO_HASH : _getNodesHash(treap, left_, right_);
    }

    function _getNodesHash(
        CMT storage treap,
        bytes32 leftNodeKey_,
        bytes32 rightNodeKey_
    ) private view returns (bytes32) {
        function(bytes32, bytes32) view returns (bytes32) hash2_ = treap.isCustomHasherSet
            ? treap.hash2
            : _hash2;

        return hash2_(leftNodeKey_, rightNodeKey_);
    }

    function _getPriorityHash(CMT storage treap, bytes32 key_) private view returns (bytes32) {
        function(bytes32) view returns (bytes32) hash1_ = treap.isCustomHasherSet
            ? treap.hash1
            : _hash1;

        return hash1_(key_);
    }

    function _hash2(bytes32 a_, bytes32 b_) private pure returns (bytes32 result_) {
        assembly {
            mstore(0, a_)
            mstore(32, b_)

            result_ := keccak256(0, 64)
        }
    }

    function _hash1(bytes32 a_) private pure returns (bytes32 result_) {
        assembly {
            mstore(0, a_)

            result_ := keccak256(0, 32)
        }
    }

    function _root(CMT storage treap) private view returns (bytes32) {
        return treap.nodes[treap.merkleRootId].merkleHash;
    }

    function _node(CMT storage treap, uint256 nodeId_) private view returns (Node memory) {
        return treap.nodes[uint64(nodeId_)];
    }

    function _desiredProofSize(CMT storage treap) private view returns (uint256) {
        return treap.desiredProofSize;
    }

    function _nodesCount(CMT storage treap) private view returns (uint256) {
        return treap.nodesCount - treap.deletedNodesCount;
    }

    function _isInitialized(CMT storage treap) private view returns (bool) {
        return treap.desiredProofSize > 0;
    }

    function _isCustomHasherSet(CMT storage treap) private view returns (bool) {
        return treap.isCustomHasherSet;
    }
}
