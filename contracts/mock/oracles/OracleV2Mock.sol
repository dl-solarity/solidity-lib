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

    function decrementCounter(address pair_) external {
        _decrementCounter(pair_);
    }

    function removePaths(address[] calldata tokenIns_) external {
        _removePaths(tokenIns_);
    }

    function setCumulativePairInfos(
        address pair_,
        uint256 price0_,
        uint256 price1_,
        uint256 index_
    ) external {
        _pairInfos[pair_].prices0Cumulative[index_] = price0_;
        _pairInfos[pair_].prices1Cumulative[index_] = price1_;
    }

    function setEmptyTimestamp(address pair_) external {
        delete _pairInfos[pair_].blockTimestamps;
    }

    function setReservesTimestamp(address pair_, uint32 blockTimestampLast_) external {
        UniswapV2PairMock(pair_).setReservesTimestamp(blockTimestampLast_);
    }

    function setTimeWindow(uint256 newTimeWindow_) external {
        _setTimeWindow(newTimeWindow_);
    }

    function setTimestamp(address pair_, uint256 newTimestamp_) external {
        uint256[] storage pairTimestamps = _pairInfos[pair_].blockTimestamps;
        pairTimestamps[pairTimestamps.length - 1] = newTimestamp_;
    }

    function getCounter(address pair_) external view returns (uint256) {
        return _pairInfos[pair_].counter;
    }

    function getPairInfosLength(
        address pair_
    ) external view returns (uint256 price0_, uint256 price1_, uint256 block_) {
        return (
            _pairInfos[pair_].prices0Cumulative.length,
            _pairInfos[pair_].prices1Cumulative.length,
            _pairInfos[pair_].blockTimestamps.length
        );
    }

    function getPath(address tokenIn_) external view returns (address[] memory) {
        return _paths[tokenIn_];
    }

    function getPriceInternal(
        address pair_,
        address expectedToken_
    ) external view returns (uint256) {
        uint256 price = _getPrice(pair_, expectedToken_);
        return price / 2 ** 112;
    }

    function ifPairRegistered(address pair_) external view returns (bool) {
        return _pairs.contains(pair_);
    }
}
