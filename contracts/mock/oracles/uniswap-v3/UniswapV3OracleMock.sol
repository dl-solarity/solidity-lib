// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {UniswapV3Oracle} from "../../../oracles/UniswapV3Oracle.sol";

contract UniswapV3OracleMock is UniswapV3Oracle {
    function __OracleV3Mock_init(address uniswapV3Factory_) external initializer {
        __OracleV3_init(uniswapV3Factory_);
    }

    function mockInit(address uniswapV3Factory_) external {
        __OracleV3_init(uniswapV3Factory_);
    }

    /*
    function getPriceOfTokenInTokenInternal(
        address baseToken_,
        address quoteToken_,
        uint24 fee_,
        uint32 period_
    ) external view {
        _getPriceOfTokenInToken(baseToken_, quoteToken_, fee_, period_);
    }*/
}
