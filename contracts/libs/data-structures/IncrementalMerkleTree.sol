// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice Incremental Merkle Tree module
 *
 * This implementation is a modification of the Incremental Merkle Tree data structure described
 * in [Deposit Contract Verification](https://github.com/runtimeverification/deposit-contract-verification/blob/master/deposit-contract-verification.pdf).
 *
 * This implementation aims to optimize and improve the original data structure.
 *
 * The main differences are:
 * - No explicit constructor; the tree is initialized when the first element is added
 * - Growth is not constrained; the height of the tree automatically increases as elements are added
 *
 * Zero hashes are computed each time the getRoot function is called.
 *
 * Gas usage for _add and _root functions (where count is the number of elements added to the tree):
 *
 * TODO: recalculate table.
 *
 * ## Usage example:
 *
 * ```
 * using IncrementalMerkleTree for IncrementalMerkleTree.UintIMT;
 *
 * IncrementalMerkleTree.UintIMT internal uintTree;
 *
 * ................................................
 *
 * uintTree.add(1234);
 *
 * uintTree.root();
 *
 * uintTree.height();
 *
 * uintTree.length();
 * ```
 */
library IncrementalMerkleTree {
    /**
     *********************
     *      UintIMT      *
     *********************
     */

    struct UintIMT {
        IMT _tree;
    }

    /**
     * @notice The Uint256 Incremental Merkle Tree constructor, creates a tree instance with the
     * given size, O(1) complex
     */
    function newUint(uint256 size_) internal pure returns (UintIMT memory imt) {
        imt._tree = _new(size_);
    }

    /**
     * @notice The function to add a new element to the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param element_ The new element to add.
     */
    function add(UintIMT storage tree, uint256 element_) internal {
        _add(tree._tree, bytes32(element_));
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1Fn_ The hash function that accepts one argument.
     * @param hash2Fn_ The hash function that accepts two arguments.
     */
    function setHashers(
        UintIMT storage tree,
        function(bytes32) view returns (bytes32) hash1Fn_,
        function(bytes32, bytes32) view returns (bytes32) hash2Fn_
    ) internal {
        _setHashers(tree._tree, hash1Fn_, hash2Fn_);
    }

    /**
     * @notice The function to return the root hash of the uint256 tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     *
     * @param tree self.
     * @return The root hash of the Merkle tree.
     */
    function root(UintIMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the uint256 tree. Complexity is O(1).
     * @param tree self.
     * @return The height of the Merkle tree.
     */
    function height(UintIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the uint256 tree. Complexity is O(1).
     * @param tree self.
     * @return The number of elements in the Merkle tree.
     */
    function length(UintIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isHashFnSet(UintIMT storage tree) internal view returns (bool) {
        return tree._tree.isHashFnSet;
    }

    /**
     **********************
     *     Bytes32IMT     *
     **********************
     */

    struct Bytes32IMT {
        IMT _tree;
    }

    /**
     * @notice The Bytes32 Incremental Merkle Tree constructor, creates a tree instance with the
     * given size, O(1) complex
     */
    function newBytes32(uint256 size_) internal pure returns (Bytes32IMT memory imt) {
        imt._tree = _new(size_);
    }

    /**
     * @notice The function to add a new element to the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     */
    function add(Bytes32IMT storage tree, bytes32 element_) internal {
        _add(tree._tree, element_);
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1Fn_ The hash function that accepts one argument.
     * @param hash2Fn_ The hash function that accepts two arguments.
     */
    function setHashers(
        Bytes32IMT storage tree,
        function(bytes32) view returns (bytes32) hash1Fn_,
        function(bytes32, bytes32) view returns (bytes32) hash2Fn_
    ) internal {
        _setHashers(tree._tree, hash1Fn_, hash2Fn_);
    }

    /**
     * @notice The function to return the root hash of the bytes32 tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     */
    function root(Bytes32IMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the bytes32 tree. Complexity is O(1).
     */
    function height(Bytes32IMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the bytes32 tree. Complexity is O(1).
     */
    function length(Bytes32IMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isHashFnSet(Bytes32IMT storage tree) internal view returns (bool) {
        return tree._tree.isHashFnSet;
    }

    /**
     ************************
     *      AddressIMT      *
     ************************
     */

    struct AddressIMT {
        IMT _tree;
    }

    /**
     * @notice The Address Incremental Merkle Tree constructor, creates a tree instance with the
     * given size, O(1) complex
     */
    function newAddress(uint256 size_) internal pure returns (AddressIMT memory imt) {
        imt._tree = _new(size_);
    }

    /**
     * @notice The function to add a new element to the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     */
    function add(AddressIMT storage tree, address element_) internal {
        _add(tree._tree, bytes32(uint256(uint160(element_))));
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1Fn_ The hash function that accepts one argument.
     * @param hash2Fn_ The hash function that accepts two arguments.
     */
    function setHashers(
        AddressIMT storage tree,
        function(bytes32) view returns (bytes32) hash1Fn_,
        function(bytes32, bytes32) view returns (bytes32) hash2Fn_
    ) internal {
        _setHashers(tree._tree, hash1Fn_, hash2Fn_);
    }

    /**
     * @notice The function to return the root hash of the address tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     */
    function root(AddressIMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the address tree. Complexity is O(1).
     */
    function height(AddressIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the address tree. Complexity is O(1).
     */
    function length(AddressIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isHashFnSet(AddressIMT storage tree) internal view returns (bool) {
        return tree._tree.isHashFnSet;
    }

    /**
     ************************
     *       InnerIMT       *
     ************************
     */

    struct IMT {
        bytes32[] branches;
        uint256 leavesCount;
        bool isHashFnSet;
        function(bytes32) view returns (bytes32) hash1Fn;
        function(bytes32, bytes32) view returns (bytes32) hash2Fn;
    }

    function _new(uint256 size_) private pure returns (IMT memory imt) {
        imt.branches = new bytes32[](size_);
    }

    function _setHashers(
        IMT storage tree,
        function(bytes32) view returns (bytes32) hash1Fn_,
        function(bytes32, bytes32) view returns (bytes32) hash2Fn_
    ) private {
        tree.isHashFnSet = true;

        tree.hash1Fn = hash1Fn_;
        tree.hash2Fn = hash2Fn_;
    }

    function _add(IMT storage tree, bytes32 element_) private {
        bytes32 resultValue_ = _hash1Fn(tree, element_);

        uint256 index_ = 0;
        uint256 size_ = ++tree.leavesCount;
        uint256 treeHeight_ = tree.branches.length;

        while (index_ < treeHeight_) {
            if (size_ & 1 == 1) {
                break;
            }

            bytes32 branch_ = tree.branches[index_];
            resultValue_ = _hash2Fn(tree, branch_, resultValue_);

            size_ >>= 1;
            ++index_;
        }

        if (index_ == treeHeight_) {
            tree.branches.push(resultValue_);
        } else {
            tree.branches[index_] = resultValue_;
        }
    }

    function _root(IMT storage tree) private view returns (bytes32) {
        uint256 treeHeight_ = tree.branches.length;

        if (treeHeight_ == 0) {
            return _getZeroHash(tree);
        }

        uint256 height_;
        uint256 size_ = tree.leavesCount;
        bytes32 root_ = _getZeroHash(tree);
        bytes32[] memory zeroHashes_ = _getZeroHashes(tree, treeHeight_);

        while (height_ < treeHeight_) {
            if (size_ & 1 == 1) {
                bytes32 branch_ = tree.branches[height_];

                root_ = _hash2Fn(tree, branch_, root_);
            } else {
                bytes32 zeroHash_ = zeroHashes_[height_];

                root_ = _hash2Fn(tree, root_, zeroHash_);
            }

            size_ >>= 1;
            ++height_;
        }

        return root_;
    }

    function _height(IMT storage tree) private view returns (uint256) {
        return tree.branches.length;
    }

    function _length(IMT storage tree) private view returns (uint256) {
        return tree.leavesCount;
    }

    function _getZeroHashes(
        IMT storage tree,
        uint256 height_
    ) private view returns (bytes32[] memory) {
        bytes32[] memory zeroHashes_ = new bytes32[](height_);

        zeroHashes_[0] = _getZeroHash(tree);

        for (uint256 i = 1; i < height_; ++i) {
            bytes32 prevHash_ = zeroHashes_[i - 1];

            zeroHashes_[i] = _hash2Fn(tree, prevHash_, prevHash_);
        }

        return zeroHashes_;
    }

    function _getZeroHash(IMT storage tree) private view returns (bytes32) {
        return _hash1Fn(tree, bytes32(0));
    }

    function _hash1Fn(IMT storage tree, bytes32 a) private view returns (bytes32 result) {
        if (tree.isHashFnSet) {
            return tree.hash1Fn(a);
        }

        assembly {
            mstore(0, a)

            result := keccak256(0, 32)
        }
    }

    function _hash2Fn(
        IMT storage tree,
        bytes32 a,
        bytes32 b
    ) private view returns (bytes32 result) {
        if (tree.isHashFnSet) {
            return tree.hash2Fn(a, b);
        }

        assembly {
            mstore(0, a)
            mstore(32, b)

            result := keccak256(0, 64)
        }
    }
}
