// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PriceFeedOracle} from "../../oracles/PriceFeedOracle.sol";

contract PriceFeedOracleMock is PriceFeedOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    function __PriceFeedOracleMock_init(
        address uniswapV2Factory_,
        uint256 timeWindow_
    ) external initializer {
        __PriceFeedOracle_init(uniswapV2Factory_, timeWindow_);
    }

    function mockInit(address uniswapV2Factory_, uint256 timeWindow_) external {
        __PriceFeedOracle_init(uniswapV2Factory_, timeWindow_);
    }

    function getPath(address tokenIn_) external view returns (address[] memory) {
        return _paths[tokenIn_];
    }

    function getPairs() external view returns (address[] memory) {
        return _pairs.values();
    }

    function getPairInfo(address pair_) external view returns (PairInfo memory) {
        return _pairInfos[pair_];
    }

    function updatePriceTwice() external {
        updatePrices();
        updatePrices();
    }

    function addIncorrectPathAndPair() external {
        _pairs.add(address(this));
        _paths[address(this)] = new address[](2);
    }

    function getPrice(address pair_, address expectedToken_) external view returns (uint256) {
        return _getPrice(pair_, expectedToken_);
    }

    function addPairs(address[] calldata pairs_) external {
        _addPairs(pairs_);
    }

    function addPaths(address[][] calldata paths_) external {
        _addPaths(paths_);
    }

    function setTimeWindow(uint256 newTimeWindow_) external {
        _setTimeWindow(newTimeWindow_);
    }

    function removePairs(address[] calldata pairs_) external {
        _removePairs(pairs_);
    }

    function removePaths(address[] calldata tokenIns_) external {
        _removePaths(tokenIns_);
    }
}
