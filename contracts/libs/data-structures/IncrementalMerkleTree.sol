// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IncrementalMerkleTree
 */
library IncrementalMerkleTree {
    /**
     ************************
     *      UintVector      *
     ************************
     */

    struct UintIMT {
        IMT _tree;
    }

    function addUint(UintIMT storage tree, uint256 element_) internal {
        _addBytes32(tree._tree, bytes32(element_));
    }

    function getRoot(UintIMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._tree);
    }

    function getTreeHeight(UintIMT storage tree) internal view returns (uint256) {
        return _getTreeHeight(tree._tree);
    }

    /**
     ************************
     *     Bytes32Vector    *
     ************************
     */

    struct Bytes32IMT {
        IMT _tree;
    }

    function addBytes32(Bytes32IMT storage tree, bytes32 element_) internal {
        _addBytes32(tree._tree, element_);
    }

    function getRoot(Bytes32IMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._tree);
    }

    function getTreeHeight(Bytes32IMT storage tree) internal view returns (uint256) {
        return _getTreeHeight(tree._tree);
    }

    /**
     ************************
     *     AddressVector    *
     ************************
     */

    struct AddressIMT {
        IMT _tree;
    }

    function addAddress(AddressIMT storage tree, address element_) internal {
        _addBytes32(tree._tree, bytes32(uint256(uint160(element_))));
    }

    function getRoot(AddressIMT storage tree) internal view returns (bytes32) {
        return _getRoot(tree._tree);
    }

    function getTreeHeight(AddressIMT storage tree) internal view returns (uint256) {
        return _getTreeHeight(tree._tree);
    }

    /**
     ************************
     *      InnerVector     *
     ************************
     */

    struct IMT {
        bytes32[] branches;
        uint256 depositCount;
    }

    bytes32 public constant ZERO_HASH = keccak256(abi.encode(0));

    function _addBytes32(IMT storage tree, bytes32 element_) private {
        bytes32 resultValue_;

        assembly {
            mstore(0, element_)
            resultValue_ := keccak256(0, 32)
        }

        uint256 index_ = 0;
        uint256 size_ = ++tree.depositCount;
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

            index_++;
        }

        if (index_ == treeHeight_) {
            tree.branches.push(resultValue_);
        } else {
            tree.branches[index_] = resultValue_;
        }
    }

    function _getRoot(IMT storage tree) private view returns (bytes32) {
        uint256 treeHeight_ = tree.branches.length;

        if (treeHeight_ == 0) {
            return ZERO_HASH;
        }

        bytes32[] memory zeroHashes_ = _getZeroHashes(treeHeight_);

        bytes32 root_ = ZERO_HASH;

        uint256 size_ = tree.depositCount;

        uint256 height_;

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

            height_++;
        }

        return root_;
    }

    function _getTreeHeight(IMT storage tree) private view returns (uint256) {
        return tree.branches.length;
    }

    function _getZeroHashes(uint256 height_) private view returns (bytes32[] memory) {
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
