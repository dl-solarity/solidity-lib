// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice Cartesian Merkle Tree Module
 *
 * Gas usage for adding and removing 5,000 elements to a treap on the Poseidon and Keccak256 Hash functions is detailed below:
 *
 * Keccak256:
 * - CMT.add - 249k
 * - CMT.remove - 181k
 *
 * Poseidon:
 * - CMT.add - 896k
 * - CMT.remove - 746k
 *
 * ## Usage Example:
 *
 * ```solidity
 * using CartesianMerkleTree for CartesianMerkleTree.UintCMT;
 *
 * CartesianMerkleTree.UintCMT internal uintTreap;
 * ...
 * uintTreap.initialize(80);
 *
 * uintTreap.add(100);
 *
 * uintTreap.getRoot();
 *
 * CartesianMerkleTree.Proof memory proof = uintTreap.getProof(100);
 *
 * uintTreap.getNodeByKey(100);
 *
 * uintTreap.remove(100);
 * ```
 */
library CartesianMerkleTree {
    /**
     *********************
     *      UintCMT      *
     *********************
     */

    struct UintCMT {
        CMT _treap;
    }

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(UintCMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treap self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        UintCMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treap._treap, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(UintCMT storage treap, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the uint256 treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function add(UintCMT storage treap, uint256 key_) internal {
        _add(treap._treap, bytes32(key_));
    }

    /**
     * @notice The function to remove an element from the uint256 treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function remove(UintCMT storage treap, uint256 key_) internal {
        _remove(treap._treap, bytes32(key_));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        UintCMT storage treap,
        uint256 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, bytes32(key_), desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treap self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(UintCMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treap self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(UintCMT storage treap, uint256 nodeId_) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        UintCMT storage treap,
        uint256 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treap._treap, bytes32(key_));
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treap self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(UintCMT storage treap) internal view returns (uint256) {
        return _desiredProofSize(treap._treap);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treap self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(UintCMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treap self.
     * @return True if custom hash function is set, otherwise false.
     */
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

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(Bytes32CMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treap self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        Bytes32CMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treap._treap, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(Bytes32CMT storage treap, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the bytes32 treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function add(Bytes32CMT storage treap, bytes32 key_) internal {
        _add(treap._treap, key_);
    }

    /**
     * @notice The function to remove an element from the bytes32 treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function remove(Bytes32CMT storage treap, bytes32 key_) internal {
        _remove(treap._treap, key_);
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        Bytes32CMT storage treap,
        bytes32 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, key_, desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treap self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(Bytes32CMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treap self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        Bytes32CMT storage treap,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        Bytes32CMT storage treap,
        bytes32 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treap._treap, key_);
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treap self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(Bytes32CMT storage treap) internal view returns (uint256) {
        return _desiredProofSize(treap._treap);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treap self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(Bytes32CMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treap self.
     * @return True if custom hash function is set, otherwise false.
     */
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

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(AddressCMT storage treap, uint32 desiredProofSize_) internal {
        _initialize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treap self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        AddressCMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treap._treap, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treap self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(AddressCMT storage treap, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treap._treap, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the address treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function add(AddressCMT storage treap, address key_) internal {
        _add(treap._treap, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to remove an element from the address treap.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     */
    function remove(AddressCMT storage treap, address key_) internal {
        _remove(treap._treap, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        AddressCMT storage treap,
        address key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treap._treap, _fromAddressToBytes32(key_), desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treap self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(AddressCMT storage treap) internal view returns (bytes32) {
        return _rootMerkleHash(treap._treap);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treap self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        AddressCMT storage treap,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treap._treap, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treap.
     *
     * @param treap self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        AddressCMT storage treap,
        address key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treap._treap, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treap self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(AddressCMT storage treap) internal view returns (uint256) {
        return _desiredProofSize(treap._treap);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treap self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(AddressCMT storage treap) internal view returns (uint64) {
        return uint64(_nodesCount(treap._treap));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treap self.
     * @return True if custom hash function is set, otherwise false.
     */
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

    /**
     * @notice Defines the structure of the Cartesian Merkle Tree.
     *
     * @param nodes A mapping of the treap's nodes, where the key is the node's index, starting from 1 upon node addition.
     *
     * @param merkleRootId The index of the root node.
     * @param nodesCount The total number of nodes within the Cartesian Merkle Tree.
     * @param deletedNodesCount The total number of the deleted nodes within the Cartesian Merkle Tree.
     * @param desiredProofSize The desired proof size of the CMT proofs.
     * @param isCustomHasherSet Indicates whether custom hash function has been configured (true) or not (false).
     * @param hash3 A hash function accepting three arguments.
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

    /**
     * @notice Describes a node within the Cartesian Merkle tree, including its children, hash, priority and key.
     *
     * @param childLeft The index of the left child node.
     * @param childRight The index of the right child node.
     * @param priority The priority of the node that counts as `keccak256(key)`
     * @param merkleHash The hash of the node, calculated as follows:
     * - H(k || child1 || child2) where k is the current node key;
     * child1 and child2 are merkleHash values of child nodes that were sorted in ascending order
     *
     * @param key The key associated with the node.
     */
    struct Node {
        uint64 childLeft;
        uint64 childRight;
        bytes16 priority;
        bytes32 merkleHash;
        bytes32 key;
    }

    /**
     * @notice Represents the proof of a node's (non-)existence within the Cartesian Merkle tree.
     *
     * @param root The root hash of the Cartesian Merkle tree.
     * @param siblings An array of sibling hashes can be used to get the Cartesian Merkle Root.
     * @param siblingsLength The number of siblings to be used for evidence.
     * @param existence Indicates the presence (true) or absence (false) of the node.
     * @param key The key associated with the node.
     * @param nonExistenceKey The non-existence key of the auxiliary node in case when existence is false.
     */
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

    function _setHasher(
        CMT storage treap,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        require(_nodesCount(treap) == 0, "CartesianMerkleTree: treap is not empty");

        treap.isCustomHasherSet = true;

        treap.hash3 = hash3_;
    }

    function _add(CMT storage treap, bytes32 key_) private onlyInitialized(treap) {
        require(key_ != 0, "CartesianMerkleTree: the key can't be zero");

        treap.merkleRootId = uint64(_add(treap, treap.merkleRootId, key_));
    }

    function _remove(CMT storage treap, bytes32 key_) private onlyInitialized(treap) {
        require(key_ != 0, "CartesianMerkleTree: the key can't be zero");

        treap.merkleRootId = uint64(_remove(treap, treap.merkleRootId, key_));
    }

    function _add(CMT storage treap, uint256 rootNodeId_, bytes32 key_) private returns (uint256) {
        Node storage rootNode = treap.nodes[uint64(rootNodeId_)];

        if (rootNode.key == 0) {
            return _newNode(treap, key_);
        }

        require(rootNode.key != key_, "CartesianMerkleTree: the key already exists");

        if (rootNode.key > key_) {
            rootNode.childLeft = uint64(_add(treap, rootNode.childLeft, key_));

            if (treap.nodes[rootNode.childLeft].priority > rootNode.priority) {
                rootNodeId_ = _rightRotate(treap, rootNodeId_);
                rootNode = treap.nodes[uint64(rootNodeId_)];
            }
        } else {
            rootNode.childRight = uint64(_add(treap, rootNode.childRight, key_));

            if (treap.nodes[rootNode.childRight].priority > rootNode.priority) {
                rootNodeId_ = _leftRotate(treap, rootNodeId_);
                rootNode = treap.nodes[uint64(rootNodeId_)];
            }
        }

        rootNode.merkleHash = _hashNodes(treap, rootNodeId_);

        return rootNodeId_;
    }

    function _remove(
        CMT storage treap,
        uint256 rootNodeId_,
        bytes32 key_
    ) private returns (uint256) {
        Node storage rootNode = treap.nodes[uint64(rootNodeId_)];

        require(rootNode.key != 0, "CartesianMerkleTree: the node does not exist");

        if (key_ < rootNode.key) {
            rootNode.childLeft = uint64(_remove(treap, rootNode.childLeft, key_));
        } else if (key_ > rootNode.key) {
            rootNode.childRight = uint64(_remove(treap, rootNode.childRight, key_));
        }

        if (rootNode.key == key_) {
            Node storage leftRootChildNode = treap.nodes[rootNode.childLeft];
            Node storage rightRootChildNode = treap.nodes[rootNode.childRight];

            if (leftRootChildNode.key == 0 || rightRootChildNode.key == 0) {
                uint64 nodeIdToRemove_ = uint64(rootNodeId_);

                rootNodeId_ = leftRootChildNode.key == 0
                    ? rootNode.childRight
                    : rootNode.childLeft;

                treap.deletedNodesCount++;
                delete treap.nodes[nodeIdToRemove_];
            } else if (leftRootChildNode.priority < rightRootChildNode.priority) {
                rootNodeId_ = _leftRotate(treap, rootNodeId_);
                rootNode = treap.nodes[uint64(rootNodeId_)];

                rootNode.childLeft = uint64(_remove(treap, rootNode.childLeft, key_));
            } else {
                rootNodeId_ = _rightRotate(treap, rootNodeId_);
                rootNode = treap.nodes[uint64(rootNodeId_)];

                rootNode.childRight = uint64(_remove(treap, rootNode.childRight, key_));
            }
        }

        rootNode.merkleHash = _hashNodes(treap, rootNodeId_);

        return rootNodeId_;
    }

    function _rightRotate(CMT storage treap, uint256 nodeId_) private returns (uint256) {
        Node storage node = treap.nodes[uint64(nodeId_)];

        uint64 leftId_ = node.childLeft;

        Node storage leftNode = treap.nodes[leftId_];

        uint64 leftRightId_ = leftNode.childRight;

        leftNode.childRight = uint64(nodeId_);
        node.childLeft = leftRightId_;

        node.merkleHash = _hashNodes(treap, nodeId_);

        return leftId_;
    }

    function _leftRotate(CMT storage treap, uint256 nodeId_) private returns (uint256) {
        Node storage node = treap.nodes[uint64(nodeId_)];

        uint64 rightId_ = node.childRight;

        Node storage rightNode = treap.nodes[rightId_];

        uint64 rightLeftId_ = rightNode.childLeft;

        rightNode.childLeft = uint64(nodeId_);
        node.childRight = rightLeftId_;

        node.merkleHash = _hashNodes(treap, nodeId_);

        return rightId_;
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

        if (treap.merkleRootId == 0) {
            return proof_;
        }

        Node storage node;
        uint256 currentSiblingsIndex_;
        uint256 nextNodeId_ = treap.merkleRootId;

        while (true) {
            node = treap.nodes[uint64(nextNodeId_)];

            if (node.key == key_) {
                _addProofSibling(
                    proof_,
                    currentSiblingsIndex_++,
                    treap.nodes[node.childLeft].merkleHash
                );
                _addProofSibling(
                    proof_,
                    currentSiblingsIndex_++,
                    treap.nodes[node.childRight].merkleHash
                );

                proof_.existence = true;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            uint64 otherNodeId_;

            if (node.key > key_) {
                otherNodeId_ = node.childRight;
                nextNodeId_ = node.childLeft;
            } else {
                otherNodeId_ = node.childLeft;
                nextNodeId_ = node.childRight;
            }

            if (nextNodeId_ == 0) {
                _addProofSibling(
                    proof_,
                    currentSiblingsIndex_++,
                    treap.nodes[node.childLeft].merkleHash
                );
                _addProofSibling(
                    proof_,
                    currentSiblingsIndex_++,
                    treap.nodes[node.childRight].merkleHash
                );

                proof_.nonExistenceKey = node.key;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            _addProofSibling(proof_, currentSiblingsIndex_++, node.key);
            _addProofSibling(
                proof_,
                currentSiblingsIndex_++,
                treap.nodes[otherNodeId_].merkleHash
            );
        }

        return proof_;
    }

    function _newNode(CMT storage treap, bytes32 key_) private returns (uint256) {
        uint64 nodeId_ = ++treap.nodesCount;

        treap.nodes[nodeId_] = Node({
            childLeft: 0,
            childRight: 0,
            priority: bytes16(keccak256(abi.encodePacked(key_))),
            merkleHash: _getNodesHash(treap, key_, 0, 0),
            key: key_
        });

        return nodeId_;
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

    function _hashNodes(CMT storage treap, uint256 nodeId_) private view returns (bytes32) {
        Node storage node = treap.nodes[uint64(nodeId_)];

        bytes32 leftHash_ = treap.nodes[node.childLeft].merkleHash;
        bytes32 rightHash_ = treap.nodes[node.childRight].merkleHash;

        if (leftHash_ > rightHash_) {
            (leftHash_, rightHash_) = (rightHash_, leftHash_);
        }

        return _getNodesHash(treap, node.key, leftHash_, rightHash_);
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

    function _nodeByKey(
        CMT storage treap,
        bytes32 key_
    ) private view returns (Node memory result_) {
        uint256 nextNodeId_ = treap.merkleRootId;

        Node storage currentNode;

        while (true) {
            currentNode = treap.nodes[uint64(nextNodeId_)];

            if (currentNode.key == 0) {
                break;
            }

            if (currentNode.key == key_) {
                result_ = currentNode;

                break;
            }

            nextNodeId_ = currentNode.key < key_ ? currentNode.childRight : currentNode.childLeft;
        }
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
