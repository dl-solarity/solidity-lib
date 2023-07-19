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
 * | Statistic | _add         | _root            |
 * | --------- | ------------ | ---------------- |
 * | count     | 106000       | 106000           |
 * | mean      | 36619 gas    | 71941 gas        |
 * | std       | 3617 gas     | 4324 gas         |
 * | min       | 34053 gas    | 28670 gas        |
 * | 25%       | 34077 gas    | 69715 gas        |
 * | 50%       | 36598 gas    | 72641 gas        |
 * | 75%       | 39143 gas    | 75557 gas        |
 * | max       | 94661 gas    | 75637 gas        |
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
     * @notice The function to add a new element to the tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param element_ The new element to add.
     */
    function add(UintIMT storage tree, uint256 element_) internal {
        _add(tree._tree, bytes32(element_));
    }

    /**
     * @notice The function to return the root hash of the tree.
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
     * @notice The function to return the height of the tree. Complexity is O(1).
     * @param tree self.
     * @return The height of the Merkle tree.
     */
    function height(UintIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the tree. Complexity is O(1).
     * @param tree self.
     * @return The number of elements in the Merkle tree.
     */
    function length(UintIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     **********************
     *     Bytes32IMT     *
     **********************
     */

    struct Bytes32IMT {
        IMT _tree;
    }

    function add(Bytes32IMT storage tree, bytes32 element_) internal {
        _add(tree._tree, element_);
    }

    function root(Bytes32IMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    function height(Bytes32IMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    function length(Bytes32IMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     ************************
     *      AddressIMT      *
     ************************
     */

    struct AddressIMT {
        IMT _tree;
    }

    function add(AddressIMT storage tree, address element_) internal {
        _add(tree._tree, bytes32(uint256(uint160(element_))));
    }

    function root(AddressIMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    function height(AddressIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    function length(AddressIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     ************************
     *       InnerIMT       *
     ************************
     */

    struct IMT {
        bytes32[] branches;
        uint256 leavesCount;
    }

    bytes32 private constant ZERO_HASH = keccak256(abi.encode(0));

    function _add(IMT storage tree, bytes32 element_) private {
        bytes32 resultValue_;

        assembly {
            mstore(0, element_)
            resultValue_ := keccak256(0, 32)
        }

        uint256 index_ = 0;
        uint256 size_ = ++tree.leavesCount;
        uint256 treeHeight_ = tree.branches.length;

        while (index_ < treeHeight_) {
            if (size_ & 1 == 1) {
                break;
            }

            bytes32 branch_ = tree.branches[index_];

            assembly {
                mstore(0, branch_)
                mstore(32, resultValue_)

                resultValue_ := keccak256(0, 64)
            }

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
            return ZERO_HASH;
        }

        uint256 height_;
        uint256 size_ = tree.leavesCount;
        bytes32 root_ = ZERO_HASH;
        bytes32[] memory zeroHashes_ = _getZeroHashes(treeHeight_);

        while (height_ < treeHeight_) {
            if (size_ & 1 == 1) {
                bytes32 branch_ = tree.branches[height_];

                assembly {
                    mstore(0, branch_)
                    mstore(32, root_)

                    root_ := keccak256(0, 64)
                }
            } else {
                bytes32 zeroHash_ = zeroHashes_[height_];

                assembly {
                    mstore(0, root_)
                    mstore(32, zeroHash_)

                    root_ := keccak256(0, 64)
                }
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

    function _getZeroHashes(uint256 height_) private pure returns (bytes32[] memory) {
        bytes32[] memory zeroHashes_ = new bytes32[](height_);

        zeroHashes_[0] = ZERO_HASH;

        for (uint256 i = 1; i < height_; ++i) {
            bytes32 result;
            bytes32 prevHash_ = zeroHashes_[i - 1];

            assembly {
                mstore(0, prevHash_)
                mstore(32, prevHash_)

                result := keccak256(0, 64)
            }

            zeroHashes_[i] = result;
        }

        return zeroHashes_;
    }
}
