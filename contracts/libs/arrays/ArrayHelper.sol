// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice A simple library to work with arrays
 */
library ArrayHelper {
    /**
     *  @notice The function to reverse an array
     *  @param arr_ the array to reverse
     *  @return reversed_ the reversed array
     */
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(string[] memory arr_) internal pure returns (string[] memory reversed_) {
        reversed_ = new string[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     *  @notice The function to insert an array into the other array
     *  @param to_ the array to insert into
     *  @param index_ the insertion starting index
     *  @param what_ the array to be inserted
     *  @return the index to start the next insertion from
     */
    function insert(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     *  @notice The function to transform an element into an array
     *  @param elem_ the element
     *  @return array_ the element as an array
     */
    function asArray(uint256 elem_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = elem_;
    }

    function asArray(address elem_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = elem_;
    }

    function asArray(string memory elem_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = elem_;
    }

    /**
     *  @notice The function to compute prefix sum array
     *  @param arr_ the initial array to be turned into the prefix sum array
     *  @return prefixes_ the prefix sum array
     */
    function countPrefixes(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory prefixes_) {
        if (arr_.length == 0) {
            return prefixes_;
        }

        prefixes_ = new uint256[](arr_.length);
        prefixes_[0] = arr_[0];

        for (uint256 i = 1; i < prefixes_.length; i++) {
            prefixes_[i] = prefixes_[i - 1] + arr_[i];
        }
    }

    /**
     *  @notice The function that calculates the sum of all array elements from
     *  `beginIndex_` to `endIndex_` inclusive using its prefix sum array
     *  @param beginIndex_ the index of the first range element
     *  @param endIndex_ the index of the last range element
     *  @return the sum of all elements of the range
     */
    function getRangeSum(
        uint256[] memory prefixes_,
        uint256 beginIndex_,
        uint256 endIndex_
    ) internal pure returns (uint256) {
        if (beginIndex_ == 0) {
            return prefixes_[endIndex_];
        }

        return prefixes_[endIndex_] - prefixes_[beginIndex_ - 1];
    }
}
