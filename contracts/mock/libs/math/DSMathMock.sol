// SPDX-License-Identifier: ALGPL-3.0-or-later-or-later
// from https://github.com/makerdao/dss/blob/master/src/jug.sol
pragma solidity ^0.8.0;

import "../../../libs/math/DSMath.sol";

contract DSMathMock {
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) external pure returns (uint256) {
        return DSMath.rpow(x, n, b);
    }
}
