// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

library CartesianMerkleTree {
    /**
     *********************
     *      UintCMT      *
     *********************
     */

    struct UintCMT {
        CMT _treap;
    }

    function initialize(UintCMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    function setHashers(
        UintCMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(treap._treap, hash3_);
    }

    function insert(UintCMT storage treap, uint256 key_) internal {
        _insert(treap._treap, bytes32(key_));
    }

    function remove(UintCMT storage treap, uint256 key_) internal {
        _remove(treap._treap, bytes32(key_));
    }

    function getProof(
        UintCMT storage treap,
        uint256 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, bytes32(key_), desiredProofSize_);
    }

    function getRootNodeId(UintCMT storage treap) internal view returns (uint256) {
        return _rootNodeId(treap._treap);
    }

    function getRoot(UintCMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    function getNode(UintCMT storage treap, uint256 nodeId_) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    function getNodesCount(UintCMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    function isCustomHasherSet(UintCMT storage treap) internal view returns (bool) {
        return _isCustomHasherSet(treap._treap);
    }

    /**
     **********************
     *     Bytes32CMT     *
     **********************
     */

    struct Bytes32CMT {
        CMT _treap;
    }

    function initialize(Bytes32CMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    function setHashers(
        Bytes32CMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(treap._treap, hash3_);
    }

    // function insert(Bytes32CMT storage treap, bytes32 key_) internal {
    //     _insert(treap._treap, key_);
    // }

    function remove(Bytes32CMT storage treap, bytes32 key_) internal {
        _remove(treap._treap, key_);
    }

    function getProof(
        Bytes32CMT storage treap,
        bytes32 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, key_, desiredProofSize_);
    }

    function getRootNodeId(Bytes32CMT storage treap) internal view returns (uint256) {
        return _rootNodeId(treap._treap);
    }

    function getRoot(Bytes32CMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    function getNode(
        Bytes32CMT storage treap,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    function getNodesCount(Bytes32CMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    function isCustomHasherSet(Bytes32CMT storage treap) internal view returns (bool) {
        return _isCustomHasherSet(treap._treap);
    }

    /**
     ************************
     *      AddressCMT      *
     ************************
     */

    struct AddressCMT {
        CMT _treap;
    }

    function initialize(AddressCMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    function setHashers(
        AddressCMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(treap._treap, hash3_);
    }

    // function insert(AddressCMT storage treap, address key_) internal {
    //     _insert(treap._treap, _fromAddressToBytes32(key_));
    // }

    function remove(AddressCMT storage treap, address key_) internal {
        _remove(treap._treap, _fromAddressToBytes32(key_));
    }

    function getProof(
        AddressCMT storage treap,
        address key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, _fromAddressToBytes32(key_), desiredProofSize_);
    }

    function getRootNodeId(AddressCMT storage treap) internal view returns (uint256) {
        return _rootNodeId(treap._treap);
    }

    function getRoot(AddressCMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    function getNode(
        AddressCMT storage treap,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    function getNodesCount(AddressCMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    function isCustomHasherSet(AddressCMT storage treap) internal view returns (bool) {
        return _isCustomHasherSet(treap._treap);
    }

    function _fromAddressToBytes32(address key_) private pure returns (bytes32 result_) {
        assembly {
            result_ := key_
        }
    }

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
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3;
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
        uint256 siblingsLength;
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
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        require(_nodesCount(treap) == 0, "CartesianMerkleTree: treap is not empty");

        treap.isCustomHasherSet = true;

        treap.hash3 = hash3_;
    }

    function _insert(CMT storage treap, bytes32 key_) private {
        require(key_ != 0, "CartesianMerkleTree: the key can't be zero");

        Node memory node_ = Node({
            childLeft: 0,
            childRight: 0,
            priority: bytes16(keccak256(abi.encodePacked(key_))),
            merkleHash: _getNodesHash(treap, key_, 0, 0),
            key: key_
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

    function _remove(CMT storage treap, bytes32 key_) private {
        require(key_ != 0, "CartesianMerkleTree: the key can't be zero");

        if (treap.merkleRootId == 0) {
            return;
        }

        (uint256 left_, uint256 tmp_) = _split(treap, treap.merkleRootId, key_);

        (uint256 toRemove_, uint256 right_) = _split(treap, tmp_, bytes32(uint256(key_) + 1));

        require(
            treap.nodes[uint64(toRemove_)].key == key_,
            "CartesianMerkleTree: the node does not exist"
        );

        treap.merkleRootId = uint64(_merge(treap, left_, right_));

        ++treap.deletedNodesCount;
        delete treap.nodes[uint64(toRemove_)];
    }

    function _proof(
        CMT storage treap,
        bytes32 key_,
        uint256 desiredProofSize_
    ) private view returns (Proof memory) {
        desiredProofSize_ = desiredProofSize_ == 0 ? _desiredProofSize(treap) : desiredProofSize_;

        Proof memory proof_ = Proof({
            root: _rootMerkleHash(treap),
            siblings: new bytes32[](desiredProofSize_),
            siblingsLength: 0,
            existence: false,
            key: key_,
            nonExistenceKey: ZERO_HASH
        });

        Node storage node;
        uint256 currentSiblingsIndex_;
        uint256 nextNodeId_ = treap.merkleRootId;

        while (true) {
            node = treap.nodes[uint64(nextNodeId_)];

            if (node.key == key_) {
                _addProofSibling(proof_, currentSiblingsIndex_++, treap.nodes[node.childLeft].key);
                _addProofSibling(
                    proof_,
                    currentSiblingsIndex_++,
                    treap.nodes[node.childRight].key
                );

                proof_.existence = true;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            _addProofSibling(proof_, currentSiblingsIndex_++, node.key);

            uint64 otherNodeId_;

            if (node.key > key_) {
                otherNodeId_ = node.childRight;
                nextNodeId_ = node.childLeft;
            } else {
                otherNodeId_ = node.childLeft;
                nextNodeId_ = node.childRight;
            }

            if (nextNodeId_ == 0) {
                _addProofSibling(proof_, currentSiblingsIndex_++, key_);

                proof_.nonExistenceKey = node.key;
                proof_.siblingsLength = currentSiblingsIndex_;

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

        node_.merkleHash = _hashNodes(treap, nodeId_);

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

        treap.nodes[uint64(nodeId_)].merkleHash = _hashNodes(treap, nodeId_);

        return nodeId_;
    }

    function _addProofSibling(
        Proof memory proof_,
        uint256 currentSiblingsIndex_,
        bytes32 siblingToAdd_
    ) private pure {
        require(
            currentSiblingsIndex_ < proof_.siblings.length,
            "CartesianMerkleTree: proof too lengthy"
        );

        proof_.siblings[currentSiblingsIndex_] = siblingToAdd_;
    }

    function _hashNodes(CMT storage treap, uint256 nodeId_) private view returns (bytes32) {
        Node storage node = treap.nodes[uint64(nodeId_)];

        bytes32 left_ = treap.nodes[node.childLeft].merkleHash;
        bytes32 right_ = treap.nodes[node.childRight].merkleHash;

        if (left_ > right_) {
            (left_, right_) = (right_, left_);
        }

        return _getNodesHash(treap, node.key, left_, right_);
    }

    function _getNodesHash(
        CMT storage treap,
        bytes32 nodeKey_,
        bytes32 leftNodeKey_,
        bytes32 rightNodeKey_
    ) private view returns (bytes32) {
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treap.isCustomHasherSet
            ? treap.hash3
            : _hash3;

        return hash3_(nodeKey_, leftNodeKey_, rightNodeKey_);
    }

    function _hash3(bytes32 a_, bytes32 b_, bytes32 c) private pure returns (bytes32 result_) {
        assembly {
            let freePtr_ := mload(64)

            mstore(freePtr_, a_)
            mstore(add(freePtr_, 32), b_)
            mstore(add(freePtr_, 64), c)

            result_ := keccak256(freePtr_, 96)
        }
    }

    function _rootNodeId(CMT storage treap) private view returns (uint64) {
        return treap.merkleRootId;
    }

    function _rootMerkleHash(CMT storage treap) private view returns (bytes32) {
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