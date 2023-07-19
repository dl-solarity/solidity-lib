// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice A simple library to work with arrays
 */
library ArrayHelper {
    /**
     * @notice The function to reverse an array
     * @param arr_ the array to reverse
     * @return reversed_ the reversed array
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

    function reverse(bytes32[] memory arr_) internal pure returns (bytes32[] memory reversed_) {
        reversed_ = new bytes32[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to insert an array into the other array
     * @param to_ the array to insert into
     * @param index_ the insertion starting index
     * @param what_ the array to be inserted
     * @return the index to start the next insertion from
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

    function insert(
        bytes32[] memory to_,
        uint256 index_,
        bytes32[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function that free memory that was allocated for array
     * @param array_ the array to crop
     * @param newLength_ the new length of the array
     * @return ref to cropped array
     */
    function crop(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure returns (uint256[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        address[] memory array_,
        uint256 newLength_
    ) internal pure returns (address[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(bool[] memory array_, uint256 newLength_) internal pure returns (bool[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        string[] memory array_,
        uint256 newLength_
    ) internal pure returns (string[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        bytes32[] memory array_,
        uint256 newLength_
    ) internal pure returns (bytes32[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    /**
     * @notice The function to compute the prefix sum array
     * @param arr_ the initial array to be turned into the prefix sum array
     * @return prefixes_ the prefix sum array
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
     * @notice The function that calculates the sum of all array elements from `beginIndex_` to
     * `endIndex_` inclusive using its prefix sum array
     * @param beginIndex_ the index of the first range element
     * @param endIndex_ the index of the last range element
     * @return the sum of all elements of the range
     */
    function getRangeSum(
        uint256[] memory prefixes_,
        uint256 beginIndex_,
        uint256 endIndex_
    ) internal pure returns (uint256) {
        require(beginIndex_ <= endIndex_, "ArrayHelper: wrong range");

        if (beginIndex_ == 0) {
            return prefixes_[endIndex_];
        }

        return prefixes_[endIndex_] - prefixes_[beginIndex_ - 1];
    }

    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than or equal to the `element_`. The time complexity is O(log n)
     * @param array_ the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array_` if no such element
     */
    function lowerBound(
        uint256[] memory array_,
        uint256 element_
    ) internal pure returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array_.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array_[mid_] >= element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than the `element_`. The time complexity is O(log n)
     * @param array_ the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array_` if no such element
     */
    function upperBound(
        uint256[] memory array_,
        uint256 element_
    ) internal pure returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array_.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array_[mid_] > element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }
}
