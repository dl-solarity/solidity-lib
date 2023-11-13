// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {UniswapV3Oracle} from "../../../oracles/UniswapV3Oracle.sol";

contract UniswapV3OracleMock is UniswapV3Oracle {
    function __OracleV3Mock_init(address uniswapV3Factory_) external initializer {
        __OracleV3_init(uniswapV3Factory_);
    }

    function mockInit(address uniswapV3Factory_) external {
        __OracleV3_init(uniswapV3Factory_);
    }
}
