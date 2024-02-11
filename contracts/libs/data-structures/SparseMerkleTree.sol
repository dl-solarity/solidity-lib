// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SparseMerkleTree {
    /**
     *********************
     *      UintSMT      *
     *********************
     */

    struct UintSMT {
        SMT _tree;
    }

    function initialize(UintSMT storage tree, uint64 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    function setMaxDepth(UintSMT storage tree, uint64 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    function setHashers(
        UintSMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    function add(UintSMT storage tree, uint256 index_, uint256 value_) internal {
        _add(tree._tree, bytes32(index_), bytes32(value_));
    }

    function getProof(UintSMT storage tree, uint256 index_) internal view returns (Proof memory) {
        return _proof(tree._tree, bytes32(index_));
    }

    function getRoot(UintSMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    function getNode(UintSMT storage tree, uint256 nodeId_) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    function getNodeByIndex(
        UintSMT storage tree,
        uint256 index_
    ) internal view returns (Node memory) {
        return _nodeByIndex(tree._tree, bytes32(index_));
    }

    function getMaxDepth(UintSMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    function getNodesCount(UintSMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    function isCustomHasherSet(UintSMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     **********************
     *     Bytes32IMT     *
     **********************
     */

    struct Bytes32SMT {
        SMT _tree;
    }

    function initialize(Bytes32SMT storage tree, uint64 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    function setMaxDepth(Bytes32SMT storage tree, uint64 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    function setHashers(
        Bytes32SMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    function add(Bytes32SMT storage tree, bytes32 index_, bytes32 value_) internal {
        _add(tree._tree, index_, value_);
    }

    function getProof(
        Bytes32SMT storage tree,
        bytes32 index_
    ) internal view returns (Proof memory) {
        return _proof(tree._tree, index_);
    }

    function getRoot(Bytes32SMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    function getNode(
        Bytes32SMT storage tree,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    function getNodeByIndex(
        Bytes32SMT storage tree,
        bytes32 index_
    ) internal view returns (Node memory) {
        return _nodeByIndex(tree._tree, index_);
    }

    function getMaxDepth(Bytes32SMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    function getNodesCount(Bytes32SMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    function isCustomHasherSet(Bytes32SMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     ************************
     *      AddressSMT      *
     ************************
     */

    struct AddressSMT {
        SMT _tree;
    }

    function initialize(AddressSMT storage tree, uint64 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    function setMaxDepth(AddressSMT storage tree, uint64 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    function setHashers(
        AddressSMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    function add(AddressSMT storage tree, bytes32 index_, address value_) internal {
        _add(tree._tree, index_, bytes32(uint256(uint160(value_))));
    }

    function getProof(
        AddressSMT storage tree,
        bytes32 index_
    ) internal view returns (Proof memory) {
        return _proof(tree._tree, index_);
    }

    function getRoot(AddressSMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    function getNode(
        AddressSMT storage tree,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    function getNodeByIndex(
        AddressSMT storage tree,
        bytes32 index_
    ) internal view returns (Node memory) {
        return _nodeByIndex(tree._tree, index_);
    }

    function getMaxDepth(AddressSMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    function getNodesCount(AddressSMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    function isCustomHasherSet(AddressSMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     ************************
     *       InnerSMT       *
     ************************
     */

    uint16 internal constant MAX_DEPTH_HARD_CAP = 256;

    uint64 internal constant ZERO_IDX = 0;

    bytes32 internal constant HASH_ZERO = bytes32(0);

    enum NodeType {
        EMPTY,
        LEAF,
        MIDDLE
    }

    struct SMT {
        mapping(uint256 => Node) nodes;
        uint64 merkleRootId;
        uint64 maxDepth;
        uint64 nodesCount;
        bool isInitialized;
        bool isCustomHasherSet;
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3;
    }

    struct Node {
        NodeType nodeType;
        uint64 childLeft;
        uint64 childRight;
        bytes32 nodeHash;
        bytes32 index;
        bytes32 value;
    }

    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        bool existence;
        bytes32 index;
        bytes32 value;
        bool auxExistence;
        bytes32 auxIndex;
        bytes32 auxValue;
    }

    modifier onlyInitialized(SMT storage tree) {
        require(_isInitialized(tree), "SparseMerkleTree: tree is not initialized");
        _;
    }

    function _initialize(SMT storage tree, uint64 maxDepth_) private {
        require(!_isInitialized(tree), "SparseMerkleTree: tree is already initialized");

        _setMaxDepth(tree, maxDepth_);
        tree.isInitialized = true;
    }

    function _setMaxDepth(SMT storage tree, uint64 maxDepth_) private {
        require(maxDepth_ > 0, "SparseMerkleTree: max depth must be greater than zero");
        require(maxDepth_ > tree.maxDepth, "SparseMerkleTree: max depth can only be increased");
        require(
            maxDepth_ <= MAX_DEPTH_HARD_CAP,
            "SparseMerkleTree: max depth is greater than hard cap"
        );

        tree.maxDepth = maxDepth_;
    }

    function _setHashers(
        SMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        require(_nodesCount(tree) == 0, "SparseMerkleTree: tree is not empty");

        tree.isCustomHasherSet = true;

        tree.hash2 = hash2_;
        tree.hash3 = hash3_;
    }

    function _isInitialized(SMT storage tree) private view returns (bool) {
        return tree.isInitialized;
    }

    function _add(SMT storage tree, bytes32 index_, bytes32 value_) private onlyInitialized(tree) {
        Node memory node_ = Node({
            nodeType: NodeType.LEAF,
            childLeft: ZERO_IDX,
            childRight: ZERO_IDX,
            nodeHash: HASH_ZERO,
            index: index_,
            value: value_
        });

        tree.merkleRootId = uint64(_add(tree, node_, tree.merkleRootId, 0));
    }

    function _proof(SMT storage tree, bytes32 index_) private view returns (Proof memory) {
        uint256 maxDepth_ = _maxDepth(tree);

        Proof memory proof_ = Proof({
            root: _root(tree),
            siblings: new bytes32[](maxDepth_),
            existence: false,
            index: index_,
            value: HASH_ZERO,
            auxExistence: false,
            auxIndex: HASH_ZERO,
            auxValue: HASH_ZERO
        });

        Node memory node_;
        uint256 nextNodeId_ = tree.merkleRootId;

        for (uint256 i = 0; i <= maxDepth_; i++) {
            node_ = _node(tree, nextNodeId_);

            if (node_.nodeType == NodeType.EMPTY) {
                break;
            } else if (node_.nodeType == NodeType.LEAF) {
                if (node_.index == proof_.index) {
                    proof_.existence = true;
                    proof_.value = node_.value;

                    break;
                } else {
                    proof_.auxExistence = true;
                    proof_.auxIndex = node_.index;
                    proof_.auxValue = node_.value;
                    proof_.value = node_.value;

                    break;
                }
            } else {
                if ((uint256(proof_.index) >> i) & 1 == 1) {
                    nextNodeId_ = node_.childRight;

                    proof_.siblings[i] = tree.nodes[node_.childLeft].nodeHash;
                } else {
                    nextNodeId_ = node_.childLeft;

                    proof_.siblings[i] = tree.nodes[node_.childRight].nodeHash;
                }
            }
        }

        return proof_;
    }

    function _add(
        SMT storage tree,
        Node memory newLeaf_,
        uint256 nodeId_,
        uint16 currentDepth_
    ) private returns (uint256) {
        // TODO: Explain why tree.maxDepth will be always greater than currentDepth_

        Node memory currentNode_ = tree.nodes[nodeId_];
        uint256 leafId_;

        if (currentNode_.nodeType == NodeType.EMPTY) {
            leafId_ = _setNode(tree, newLeaf_);
        } else if (currentNode_.nodeType == NodeType.LEAF) {
            leafId_ = currentNode_.index == newLeaf_.index
                ? _setNode(tree, newLeaf_)
                : _pushLeaf(tree, newLeaf_, currentNode_, nodeId_, currentDepth_);
        } else {
            Node memory newNodeMiddle_;
            uint256 nextNodeId_;

            if ((uint256(newLeaf_.index) >> currentDepth_) & 1 == 1) {
                nextNodeId_ = _add(tree, newLeaf_, currentNode_.childRight, currentDepth_ + 1);

                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: currentNode_.childLeft,
                    childRight: uint64(nextNodeId_),
                    nodeHash: HASH_ZERO,
                    index: HASH_ZERO,
                    value: HASH_ZERO
                });
            } else {
                nextNodeId_ = _add(tree, newLeaf_, currentNode_.childLeft, currentDepth_ + 1);

                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: uint64(nextNodeId_),
                    childRight: currentNode_.childRight,
                    nodeHash: HASH_ZERO,
                    index: HASH_ZERO,
                    value: HASH_ZERO
                });
            }

            leafId_ = _setNode(tree, newNodeMiddle_);
        }

        return leafId_;
    }

    function _pushLeaf(
        SMT storage tree,
        Node memory newLeaf_,
        Node memory oldLeaf_,
        uint256 oldLeafId_,
        uint16 currentDepth_
    ) private returns (uint256) {
        require(currentDepth_ < tree.maxDepth, "SparseMerkleTree: max depth reached");

        Node memory newNodeMiddle_;
        bool newLeafBitAtDepth_ = (uint256(newLeaf_.index) >> currentDepth_) & 1 == 1;
        bool oldLeafBitAtDepth_ = (uint256(oldLeaf_.index) >> currentDepth_) & 1 == 1;

        // Check if we need to go deeper if diverge at the depth's bit
        if (newLeafBitAtDepth_ == oldLeafBitAtDepth_) {
            uint256 nextNodeId_ = _pushLeaf(
                tree,
                newLeaf_,
                oldLeaf_,
                oldLeafId_,
                currentDepth_ + 1
            );

            if (newLeafBitAtDepth_) {
                // go right
                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: ZERO_IDX,
                    childRight: uint64(nextNodeId_),
                    nodeHash: HASH_ZERO,
                    index: HASH_ZERO,
                    value: HASH_ZERO
                });
            } else {
                // go left
                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: uint64(nextNodeId_),
                    childRight: ZERO_IDX,
                    nodeHash: HASH_ZERO,
                    index: HASH_ZERO,
                    value: HASH_ZERO
                });
            }

            return _setNode(tree, newNodeMiddle_);
        }

        uint256 newLeafId = _setNode(tree, newLeaf_);

        if (newLeafBitAtDepth_) {
            newNodeMiddle_ = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: uint64(oldLeafId_),
                childRight: uint64(newLeafId),
                nodeHash: HASH_ZERO,
                index: HASH_ZERO,
                value: HASH_ZERO
            });
        } else {
            newNodeMiddle_ = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: uint64(newLeafId),
                childRight: uint64(oldLeafId_),
                nodeHash: HASH_ZERO,
                index: HASH_ZERO,
                value: HASH_ZERO
            });
        }

        return _setNode(tree, newNodeMiddle_);
    }

    function _setNode(SMT storage tree, Node memory node_) private returns (uint256) {
        node_.nodeHash = _getNodeHash(tree, node_);

        uint256 newSize_ = ++tree.nodesCount;
        tree.nodes[newSize_] = node_;

        return newSize_;
    }

    // TODO: Explain why Empty nodes cannot be passed to the function
    function _getNodeHash(SMT storage tree, Node memory node_) private view returns (bytes32) {
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = tree.isCustomHasherSet
            ? tree.hash3
            : _hash3;

        if (node_.nodeType == NodeType.LEAF) {
            return hash3_(node_.index, node_.value, bytes32(uint256(1)));
        }

        return hash2_(tree.nodes[node_.childLeft].nodeHash, tree.nodes[node_.childRight].nodeHash);
    }

    function _hash2(bytes32 a, bytes32 b) private pure returns (bytes32 result) {
        assembly {
            mstore(0, a)
            mstore(0x20, b)

            result := keccak256(0, 0x40)
        }
    }

    function _hash3(bytes32 a, bytes32 b, bytes32 c) private pure returns (bytes32 result) {
        assembly {
            let free_ptr := mload(0x40)

            mstore(free_ptr, a)
            mstore(add(free_ptr, 0x20), b)
            mstore(add(free_ptr, 0x40), c)

            result := keccak256(free_ptr, 0x60)
        }
    }

    function _root(SMT storage tree) private view onlyInitialized(tree) returns (bytes32) {
        return tree.nodes[tree.merkleRootId].nodeHash;
    }

    function _node(SMT storage tree, uint256 nodeId_) private view returns (Node memory) {
        return tree.nodes[nodeId_];
    }

    function _nodeByIndex(SMT storage tree, bytes32 index_) private view returns (Node memory) {
        Node memory node_;
        uint256 nextNodeId_ = tree.merkleRootId;

        for (uint256 i = 0; i <= tree.maxDepth; i++) {
            node_ = tree.nodes[nextNodeId_];

            if (node_.nodeType == NodeType.EMPTY) {
                break;
            } else if (node_.nodeType == NodeType.LEAF) {
                if (node_.index == index_) {
                    break;
                }
            } else {
                if ((uint256(index_) >> i) & 1 == 1) {
                    nextNodeId_ = node_.childRight;
                } else {
                    nextNodeId_ = node_.childLeft;
                }
            }
        }

        return
            node_.index == index_
                ? node_
                : Node({
                    nodeType: NodeType.EMPTY,
                    childLeft: ZERO_IDX,
                    childRight: ZERO_IDX,
                    nodeHash: HASH_ZERO,
                    index: HASH_ZERO,
                    value: HASH_ZERO
                });
    }

    function _maxDepth(SMT storage tree) private view returns (uint256) {
        return tree.maxDepth;
    }

    function _nodesCount(SMT storage tree) private view returns (uint256) {
        return tree.nodesCount;
    }

    function _isCustomHasherSet(SMT storage tree) private view returns (bool) {
        return tree.isCustomHasherSet;
    }
}
