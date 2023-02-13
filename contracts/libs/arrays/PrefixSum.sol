// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PrefixSum {
    function countPrefixes(
        uint256[] memory arr
    ) internal pure returns (uint256[] memory prefixes_) {
        if (arr.length == 0) {
            return prefixes_;
        }

        prefixes_ = new uint256[](arr.length);
        prefixes_[0] = arr[0];

        for (uint256 i = 1; i < prefixes_.length; i++) {
            prefixes_[i] = prefixes_[i - 1] + arr[i];
        }
    }

    function getRangeSum(
        uint256[] memory prefixes,
        uint256 beginIndex_,
        uint256 endIndex_
    ) internal pure returns (uint256) {
        if (beginIndex_ == 0) {
            return prefixes[endIndex_];
        }

        return prefixes[endIndex_] - prefixes[beginIndex_ - 1];
    }
}
