// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import {UniswapV3Oracle} from "../../../oracles/UniswapV3Oracle.sol";

contract UniswapV3OracleMock is UniswapV3Oracle {
    constructor(address uniswapV3Factory_) UniswapV3Oracle(uniswapV3Factory_) {}
}
