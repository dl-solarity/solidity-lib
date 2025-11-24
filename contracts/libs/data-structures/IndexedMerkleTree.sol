// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice Indexed Merkle Tree Module
 *
 * Gas usage for adding and updating 100 elements to an IndexedMT with the keccak256 and poseidon hash functions is detailed below:
 *
 * Keccak256:
 * - CMT.add - 249k
 * - CMT.update - 250k
 *
 * Poseidon:
 * - CMT.add - 1.13m
 * - CMT.update - 1.13m
 *
 * Custom hashing functions can be provided before initialization to change how nodes and
 * leaves are hashed (useful for e.g. Poseidon-based hashing in zk environments). Default
 * keccak based hashing functions are used when custom hashers are not set.
 *
 * ## Usage Example
 *
 * ```solidity
 * using IndexedMerkleTree for IndexedMerkleTree.UintIndexedMT;
 *
 * IndexedMerkleTree.UintIndexedMT internal tree;
 *
 * tree.setHashers(hashFunctions);
 * tree.initialize();
 *
 * uint256 leafIndex = tree.add(42, 0);
 *
 * IndexedMerkleTree.Proof memory proof = tree.getProof(leafIndex, 42);
 *
 * bool ok = tree.verifyProof(proof);
 *```
 */

library IndexedMerkleTree {
    /**
     **************************
     *      UintIndexedMT     *
     **************************
     */

    struct UintIndexedMT {
        IndexedMT _indexedMT;
    }

    /**
     * @notice Initialize the in-storage Indexed Merkle tree wrapper for uint values.
     *
     * Requirements:
     * - The tree must not already be initialized.
     *
     * @param tree self.
     */
    function initialize(UintIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    /**
     * @notice Set custom hashing functions to be used by the tree.
     *
     * Requirements:
     * - Must be called before the tree is initialized.
     *
     * @param tree self.
     * @param hashFunctions_ The hash function container (hash2 and hash4).
     */
    function setHashers(UintIndexedMT storage tree, HashFunctions memory hashFunctions_) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    /**
     * @notice Add a new uint value to the Indexed Merkle tree.
     *
     * Complexity: O(log(levels)) where levels is the current tree height.
     *
     * @param tree self.
     * @param value_ The value to insert.
     * @param lowLeafIndex_ A known low leaf index indicating insertion position.
     * @return The new leaf index for the inserted value.
     */
    function add(
        UintIndexedMT storage tree,
        uint256 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(value_), lowLeafIndex_);
    }

    /**
     * @notice Update an existing leaf in the Indexed Merkle tree.
     *
     * Requirements:
     * - leafIndex_ must be valid and initialized.
     *
     * @param tree self.
     * @param leafIndex_ The index of the leaf to update.
     * @param currentLowLeafIndex_ The current low-leaf insertion point that precedes the leaf.
     * @param newValue_ New value to set.
     * @param newLowLeafIndex_ New low-leaf pointer (may be same as currentLowLeafIndex_).
     */
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

    /**
     * @notice Generate an inclusion/exclusion proof for the leaf at `index_`.
     *
     * Complexity: O(levels) to build the proof.
     *
     * @param tree self.
     * @param index_ The leaf index to build the proof for.
     * @param value_ The value expected at the index (used to validate existence vs exclusion).
     * @return A merkle Proof structure for `index_` and `value_`.
     */
    function getProof(
        UintIndexedMT storage tree,
        uint256 index_,
        uint256 value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, bytes32(value_));
    }

    /**
     * @notice Verify a proof produced by `getProof` for this tree instance.
     *
     * @param tree self.
     * @param proof_ The proof to verify.
     * @return True if the proof matches the current root, false otherwise.
     */
    function verifyProof(
        UintIndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    /**
     * @notice Convenience helper to process a raw Proof using the default hashers (keccak256).
     *
     * @param proof_ A proof as returned by `getProof`.
     * @return The computed root when hashing the proof values using default hash functions.
     */
    function processProof(Proof memory proof_) internal view returns (bytes32) {
        return _processProof(proof_, HashFunctions({hash2: _hash2, hash4: _hash4}));
    }

    /**
     * @notice Process a proof using the provided hash functions.
     *
     * @param proof_ A proof as returned by `getProof`.
     * @param hashFunctions_ Custom hashing functions to use when processing the proof.
     * @return The computed root when hashing the proof using the provided functions.
     */
    function processProof(
        Proof memory proof_,
        HashFunctions memory hashFunctions_
    ) internal view returns (bytes32) {
        return _processProof(proof_, hashFunctions_);
    }

    /**
     * @notice Get the current Merkle root for the tree.
     *
     * @param tree self.
     * @return The bytes32 root hash.
     */
    function getRoot(UintIndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    /**
     * @notice Get the current number of levels in the Indexed Merkle tree.
     *
     * @param tree self.
     * @return The number of levels used by the tree (>= 1 when initialized).
     */
    function getTreeLevels(UintIndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    /**
     * @notice Read data for a leaf in the tree.
     *
     * @param tree self.
     * @param leafIndex_ The leaf index to query.
     * @return LeafData struct with value and nextLeafIndex.
     */
    function getLeafData(
        UintIndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    /**
     * @notice Get the hash of a node at a given index and level.
     *
     * @param tree self.
     * @param index_ Index of the node on the provided level.
     * @param level_ Level to query (0 == leaves).
     * @return The node hash.
     */
    function getNodeHash(
        UintIndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    /**
     * @notice Get the total number of leaves in the tree.
     *
     * @param tree self.
     * @return The number of leaves stored at level 0.
     */
    function getLeavesCount(UintIndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    /**
     * @notice Get the number of nodes present at a specific level of the tree.
     *
     * @param tree self.
     * @param level_ The level to query.
     * @return The number of nodes in the specified level.
     */
    function getLevelNodesCount(
        UintIndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    /**
     * @notice Returns true when custom hash functions were provided before initialization.
     *
     * @param tree self.
     * @return True if custom hashers are set, false otherwise.
     */
    function isCustomHasherSet(UintIndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    /**
     **************************
     *    Bytes32IndexedMT    *
     **************************
     */

    struct Bytes32IndexedMT {
        IndexedMT _indexedMT;
    }

    /**
     * @notice Initialize the in-storage Indexed Merkle tree wrapper for bytes32 values.
     *
     * Requirements:
     * - The tree must not already be initialized.
     *
     * @param tree self.
     */
    function initialize(Bytes32IndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    /**
     * @notice Set custom hashing functions to be used by the tree.
     *
     * Requirements:
     * - Must be called before the tree is initialized.
     *
     * @param tree self.
     * @param hashFunctions_ The hash function container (hash2 and hash4).
     */
    function setHashers(
        Bytes32IndexedMT storage tree,
        HashFunctions memory hashFunctions_
    ) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    /**
     * @notice Add a new bytes32 value to the Indexed Merkle tree.
     *
     * Complexity: O(log(levels)) where levels is the current tree height.
     *
     * @param tree self.
     * @param value_ The value to insert.
     * @param lowLeafIndex_ A known low leaf index indicating insertion position.
     * @return The new leaf index for the inserted value.
     */
    function add(
        Bytes32IndexedMT storage tree,
        bytes32 value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, value_, lowLeafIndex_);
    }

    /**
     * @notice Update an existing leaf in the Indexed Merkle tree.
     *
     * Requirements:
     * - leafIndex_ must be valid and initialized.
     *
     * @param tree self.
     * @param leafIndex_ The index of the leaf to update.
     * @param currentLowLeafIndex_ The current low-leaf insertion point that precedes the leaf.
     * @param newValue_ New value to set.
     * @param newLowLeafIndex_ New low-leaf pointer (may be same as currentLowLeafIndex_).
     */
    function update(
        Bytes32IndexedMT storage tree,
        uint256 leafIndex_,
        uint256 currentLowLeafIndex_,
        bytes32 newValue_,
        uint256 newLowLeafIndex_
    ) internal {
        _update(tree._indexedMT, leafIndex_, currentLowLeafIndex_, newValue_, newLowLeafIndex_);
    }

    /**
     * @notice Generate an inclusion/exclusion proof for the leaf at `index_`.
     *
     * Complexity: O(levels) to build the proof.
     *
     * @param tree self.
     * @param index_ The leaf index to build the proof for.
     * @param value_ The value expected at the index (used to validate existence vs exclusion).
     * @return A merkle Proof structure for `index_` and `value_`.
     */
    function getProof(
        Bytes32IndexedMT storage tree,
        uint256 index_,
        bytes32 value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, value_);
    }

    /**
     * @notice Verify a proof produced by `getProof` for this tree instance.
     *
     * @param tree self.
     * @param proof_ The proof to verify.
     * @return True if the proof matches the current root, false otherwise.
     */
    function verifyProof(
        Bytes32IndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    /**
     * @notice Get the current Merkle root for the tree.
     *
     * @param tree self.
     * @return The bytes32 root hash.
     */
    function getRoot(Bytes32IndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    /**
     * @notice Get the current number of levels in the Indexed Merkle tree.
     *
     * @param tree self.
     * @return The number of levels used by the tree (>= 1 when initialized).
     */
    function getTreeLevels(Bytes32IndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    /**
     * @notice Read data for a leaf in the tree.
     *
     * @param tree self.
     * @param leafIndex_ The leaf index to query.
     * @return LeafData struct with value and nextLeafIndex.
     */
    function getLeafData(
        Bytes32IndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    /**
     * @notice Get the hash of a node at a given index and level.
     *
     * @param tree self.
     * @param index_ Index of the node on the provided level.
     * @param level_ Level to query (0 == leaves).
     * @return The node hash.
     */
    function getNodeHash(
        Bytes32IndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    /**
     * @notice Get the total number of leaves in the tree.
     *
     * @param tree self.
     * @return The number of leaves stored at level 0.
     */
    function getLeavesCount(Bytes32IndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    /**
     * @notice Get the number of nodes present at a specific level of the tree.
     *
     * @param tree self.
     * @param level_ The level to query.
     * @return The number of nodes in the specified level.
     */
    function getLevelNodesCount(
        Bytes32IndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    /**
     * @notice Returns true when custom hash functions were provided before initialization.
     *
     * @param tree self.
     * @return True if custom hashers are set, false otherwise.
     */
    function isCustomHasherSet(Bytes32IndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    /**
     **************************
     *    AddressIndexedMT    *
     **************************
     */

    struct AddressIndexedMT {
        IndexedMT _indexedMT;
    }

    /**
     * @notice Initialize the in-storage Indexed Merkle tree wrapper for address values.
     *
     * Requirements:
     * - The tree must not already be initialized.
     *
     * @param tree self.
     */
    function initialize(AddressIndexedMT storage tree) internal {
        _initialize(tree._indexedMT);
    }

    /**
     * @notice Set custom hashing functions to be used by the tree.
     *
     * Requirements:
     * - Must be called before the tree is initialized.
     *
     * @param tree self.
     * @param hashFunctions_ The hash function container (hash2 and hash4).
     */
    function setHashers(
        AddressIndexedMT storage tree,
        HashFunctions memory hashFunctions_
    ) internal {
        _setHashers(tree._indexedMT, hashFunctions_);
    }

    /**
     * @notice Add a new address value to the Indexed Merkle tree.
     *
     * Complexity: O(log(levels)) where levels is the current tree height.
     *
     * @param tree self.
     * @param value_ The address value to insert.
     * @param lowLeafIndex_ A known low leaf index indicating insertion position.
     * @return The new leaf index for the inserted value.
     */
    function add(
        AddressIndexedMT storage tree,
        address value_,
        uint256 lowLeafIndex_
    ) internal returns (uint256) {
        return _add(tree._indexedMT, bytes32(uint256(uint160(value_))), lowLeafIndex_);
    }

    /**
     * @notice Update an existing leaf in the Indexed Merkle tree.
     *
     * Requirements:
     * - leafIndex_ must be valid and initialized.
     *
     * @param tree self.
     * @param leafIndex_ The index of the leaf to update.
     * @param currentLowLeafIndex_ The current low-leaf insertion point that precedes the leaf.
     * @param newValue_ New address value to set.
     * @param newLowLeafIndex_ New low-leaf pointer (may be same as currentLowLeafIndex_).
     */
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

    /**
     * @notice Generate an inclusion/exclusion proof for the leaf at `index_`.
     *
     * Complexity: O(levels) to build the proof.
     *
     * @param tree self.
     * @param index_ The leaf index to build the proof for.
     * @param value_ The value expected at the index (used to validate existence vs exclusion).
     * @return A merkle Proof structure for `index_` and `value_`.
     */
    function getProof(
        AddressIndexedMT storage tree,
        uint256 index_,
        address value_
    ) internal view returns (Proof memory) {
        return _proof(tree._indexedMT, index_, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice Verify a proof produced by `getProof` for this tree instance.
     *
     * @param tree self.
     * @param proof_ The proof to verify.
     * @return True if the proof matches the current root, false otherwise.
     */
    function verifyProof(
        AddressIndexedMT storage tree,
        Proof memory proof_
    ) internal view returns (bool) {
        return _verifyProof(tree._indexedMT, proof_);
    }

    /**
     * @notice Get the current Merkle root for the tree.
     *
     * @param tree self.
     * @return The bytes32 root hash.
     */
    function getRoot(AddressIndexedMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._indexedMT);
    }

    /**
     * @notice Get the current number of levels in the Indexed Merkle tree.
     *
     * @param tree self.
     * @return The number of levels used by the tree (>= 1 when initialized).
     */
    function getTreeLevels(AddressIndexedMT storage tree) internal view returns (uint256) {
        return _getTreeLevels(tree._indexedMT);
    }

    /**
     * @notice Read data for a leaf in the tree.
     *
     * @param tree self.
     * @param leafIndex_ The leaf index to query.
     * @return LeafData struct with value and nextLeafIndex.
     */
    function getLeafData(
        AddressIndexedMT storage tree,
        uint256 leafIndex_
    ) internal view returns (LeafData memory) {
        return _getLeafData(tree._indexedMT, leafIndex_);
    }

    /**
     * @notice Get the hash of a node at a given index and level.
     *
     * @param tree self.
     * @param index_ Index of the node on the provided level.
     * @param level_ Level to query (0 == leaves).
     * @return The node hash.
     */
    function getNodeHash(
        AddressIndexedMT storage tree,
        uint256 index_,
        uint256 level_
    ) internal view returns (bytes32) {
        return _getNodeHash(tree._indexedMT, index_, level_);
    }

    /**
     * @notice Get the total number of leaves in the tree.
     *
     * @param tree self.
     * @return The number of leaves stored at level 0.
     */
    function getLeavesCount(AddressIndexedMT storage tree) internal view returns (uint256) {
        return _getLeavesCount(tree._indexedMT);
    }

    /**
     * @notice Get the number of nodes present at a specific level of the tree.
     *
     * @param tree self.
     * @param level_ The level to query.
     * @return The number of nodes in the specified level.
     */
    function getLevelNodesCount(
        AddressIndexedMT storage tree,
        uint256 level_
    ) internal view returns (uint256) {
        return _getLevelNodesCount(tree._indexedMT, level_);
    }

    /**
     * @notice Returns true when custom hash functions were provided before initialization.
     *
     * @param tree self.
     * @return True if custom hashers are set, false otherwise.
     */
    function isCustomHasherSet(AddressIndexedMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._indexedMT);
    }

    /**
     **************************
     *     InnerIndexedMT     *
     **************************
     */

    /**
     * @notice Level index used for leaf nodes.
     */
    uint256 internal constant LEAVES_LEVEL = 0;

    /**
     * @notice A sentinel zero index used in linked-leaf pointers.
     */
    uint64 internal constant ZERO_IDX = 0;

    /**
     * @notice Zero hash representation used for empty nodes / default values.
     */
    bytes32 internal constant ZERO_HASH = bytes32(0);

    /**
     * @notice Core storage structure for the Indexed Merkle tree.
     *
     * @param leavesData compact storage of leaf metadata (value + pointer to next leaf).
     * @param nodes mapping of level => array of node hashes; level 0 is leaves, top index is root.
     * @param levelsCount current number of levels present in the tree (>= 1 after init).
     * @param isCustomHasherSet true when caller provided custom hash functions before init.
     * @param hash2 A two-input hash function used to hash node pairs.
     * @param hash4 A four-input hash function used to hash leaf metadata (active flag, idx, value, nextIndex).
     */
    struct IndexedMT {
        LeafData[] leavesData;
        mapping(uint256 level => bytes32[] nodeHashes) nodes;
        uint256 levelsCount;
        bool isCustomHasherSet;
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32, bytes32) view returns (bytes32) hash4;
    }

    /**
     * @notice Container type for custom hashing functions.
     */
    struct HashFunctions {
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32, bytes32) view returns (bytes32) hash4;
    }

    /**
     * @notice Merkle proof returned by `getProof` and used by `verifyProof`.
     *
     * @param root The root hash for which this proof should verify.
     * @param siblings Array of sibling hashes used to reconstruct the root from the leaf.
     * @param existence Whether the supplied index/value exists (true) or this is an exclusion proof (false).
     * @param index The leaf index (position) within the leaves level used to compute the proof.
     * @param value The stored value for the leaf referenced by `index` (or candidate value for an exclusion check).
     * @param nextLeafIndex For the indexed tree the leaf contains a pointer to the next leaf; used when hashing leaves.
     */
    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        bool existence;
        uint256 index;
        bytes32 value;
        uint256 nextLeafIndex;
    }

    /**
     * @notice The main leaf metadata struct
     * @param value The stored bytes32 value for the leaf.
     * @param nextLeafIndex Index of the next active leaf (ZERO_IDX when none).
     */
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

    /**
     * @dev This will create the empty-leaf sentinel and push the initial leaf and the
     * corresponding zero-hash for the leaves level. The function reverts if the
     * tree is already initialized.
     */
    function _initialize(IndexedMT storage tree) private {
        if (_isInitialized(tree)) revert IndexedMerkleTreeAlreadyInitialized();

        tree.leavesData.push(LeafData({value: ZERO_HASH, nextLeafIndex: ZERO_IDX}));
        tree.nodes[LEAVES_LEVEL].push(_hashLeaf(0, 0, 0, true, _getHashFunctions(tree).hash4));

        tree.levelsCount++;
    }

    /**
     * @dev Set custom hash functions for the indexed tree.
     * Must be invoked before initialization (otherwise the tree is already created).
     */
    function _setHashers(IndexedMT storage tree, HashFunctions memory hashFunctions_) private {
        if (_isInitialized(tree)) revert IndexedMerkleTreeAlreadyInitialized();

        tree.isCustomHasherSet = true;

        tree.hash2 = hashFunctions_.hash2;
        tree.hash4 = hashFunctions_.hash4;
    }

    /**
     * @dev Insert a new leaf into the indexed tree at the position following lowLeafIndex_.
     * Performs necessary checks that lowLeafIndex_ is a valid low-leaf and then updates
     * the data structures and merkle node hashes accordingly.
     *
     * @return The newly allocated leaf index.
     */
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

    /**
     * @dev Update stored value and optionally reposition the leaf by modifying
     * the nextLeafIndex links. The function validates provided low-leaf pointers
     * and updates merkle node hashes for affected leaves.
     */
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

    /**
     * @dev Validate whether `lowLeafIndex_` is a valid low leaf for the supplied value_.
     * If valid, returns the next leaf index after the low leaf.
     */
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

    /**
     * @dev Returns true when `lowLeafIndex_` is an insertion point for `value_`.
     * That means low leaf's value is < value_ and the next leaf's value (if present)
     * is strictly greater than value_.
     */
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

    /**
     * @dev Return the canonical zero node hash for a given level. For level 0 this is
     * the hash of an inactive leaf; for higher levels it is the hash of two identical
     * zero child hashes.
     */
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
