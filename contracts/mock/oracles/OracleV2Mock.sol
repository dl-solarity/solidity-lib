// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OracleV2} from "../../oracles/OracleV2.sol";
import {UniswapV2PairMock} from "./UniswapV2PairMock.sol";

contract OracleV2Mock is OracleV2 {
    using EnumerableSet for EnumerableSet.AddressSet;

    function __OracleV2Mock_init(
        address uniswapV2Factory_,
        uint256 timeWindow_
    ) external initializer {
        __OracleV2_init(uniswapV2Factory_, timeWindow_);
    }

    function mockInit(address uniswapV2Factory_, uint256 timeWindow_) external {
        __OracleV2_init(uniswapV2Factory_, timeWindow_);
    }

    function addPaths(address[][] calldata paths_) external {
        _addPaths(paths_);
    }

    function removePaths(address[] calldata tokenIns_) external {
        _removePaths(tokenIns_);
    }

    function setTimeWindow(uint256 newTimeWindow_) external {
        _setTimeWindow(newTimeWindow_);
    }

    function setReservesTimestamp(address pair_, uint32 blockTimestampLast_) external {
        UniswapV2PairMock(pair_).setReservesTimestamp(blockTimestampLast_);
    }
}
