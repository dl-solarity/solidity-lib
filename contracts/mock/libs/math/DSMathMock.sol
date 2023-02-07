// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/math/DSMath.sol";

contract DSMathMock {
    function rpow(uint256 x_, uint256 n_, uint256 b_) external pure returns (uint256) {
        return DSMath.rpow(x_, n_, b_);
    }

    function sqrt(uint256 x_) external pure returns (uint256) {
        return DSMath.sqrt(x_);
    }
}
