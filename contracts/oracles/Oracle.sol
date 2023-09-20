// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UniswapV2OracleLibrary} from "./external-modules/uniswap-v2/v2-periphery/UniswapV2OracleLibrary.sol";

import {ArrayHelper} from "../libs/arrays/ArrayHelper.sol";

/**
 * @title PriceFeedOracle
 * @dev A contract for retrieving price feeds from Uniswap V2 pairs.
 */
abstract contract Oracle is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using UniswapV2OracleLibrary for address;
    using ArrayHelper for uint256[];
    using Math for uint256;

    struct PairInfo {
        uint256[] prices0Cumulative;
        uint256[] prices1Cumulative;
        uint256[] blockTimestamps;
    }

    IUniswapV2Factory public uniswapV2Factory;

    uint256 public timeWindow;

    EnumerableSet.AddressSet internal _pairs;
    mapping(address => uint256) internal _pairCounters;
    mapping(address => address[]) internal _paths;
    mapping(address => PairInfo) internal _pairInfos;

    function __Oracle_init(
        address uniswapV2Factory_,
        uint256 timeWindow_
    ) internal onlyInitializing {
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Factory_);
        timeWindow = timeWindow_;
    }

    /**
     * @dev Updates the price data for all registered Uniswap V2 pairs.
     */
    function updatePrices() public {
        for (uint256 i = 0; i < _pairs.length(); i++) {
            address pair = _pairs.at(i);

            PairInfo storage pairInfo = _pairInfos[pair];
            uint256[] storage pairTimestamps = pairInfo.blockTimestamps;

            (uint256 price0Cumulative, uint256 price1Cumulative, uint256 blockTimestamp) = pair
                .currentCumulativePrices();

            if (
                pairTimestamps.length == 0 ||
                blockTimestamp > pairTimestamps[pairTimestamps.length - 1]
            ) {
                pairInfo.prices0Cumulative.push(price0Cumulative);
                pairInfo.prices1Cumulative.push(price1Cumulative);
                pairInfo.blockTimestamps.push(blockTimestamp);
            }
        }
    }

    /**
     * @dev Retrieves the price of a token based on the provided token and amount.
     * @param tokenIn_ The input token address.
     * @param amount_ The amount of the input token.
     * @return The price in last token of the path and the output token address.
     */
    function getPrice(address tokenIn_, uint256 amount_) external view returns (uint256, address) {
        address[] storage path = _paths[tokenIn_];

        require(path.length > 0, "Oracle: invalid path");

        address tokenOut_ = path[path.length - 1];

        for (uint256 i = 0; i < path.length - 1; i++) {
            address currentToken = path[i];
            address nextToken = path[i + 1];

            address pair = uniswapV2Factory.getPair(currentToken, nextToken);

            uint256 price = _getPrice(pair, currentToken);

            if (price == 0) {
                return (0, tokenOut_);
            }

            amount_ = price.mulDiv(amount_, 2 ** 112);
        }

        return (amount_, tokenOut_);
    }

    /**
     * @dev Sets the time window for fetching price data.
     * @param newTimeWindow_ The new time window value in seconds.
     */
    function _setTimeWindow(uint256 newTimeWindow_) internal {
        timeWindow = newTimeWindow_;
    }

    /**
     * @dev Adds multiple token paths to the oracle.
     * @param paths_ The array of token paths to add.
     */
    function _addPaths(address[][] calldata paths_) internal {
        for (uint256 i = 0; i < paths_.length; i++) {
            require(paths_[i].length >= 2, "Oracle: path must be longer than 2");

            for (uint256 j = 0; j < paths_[i].length - 1; j++) {
                (bool isExist, address pair) = _isPairExistAtUniswap(
                    paths_[i][j],
                    paths_[i][j + 1]
                );
                require(isExist, "Oracle: uniswap pair doesn't exist");
                _pairs.add(pair);
                _incrementCounter(pair);
            }
            _paths[paths_[i][0]] = paths_[i];
        }
        updatePrices();
    }

    /**
     * @dev Removes multiple token paths from the oracle.
     * @param tokenIns_ The array of token addresses to remove.
     */
    function _removePaths(address[] calldata tokenIns_) internal {
        for (uint256 i = 0; i < tokenIns_.length; i++) {
            for (uint256 j = 0; j < _paths[tokenIns_[i]].length - 1; j++) {
                address pair = uniswapV2Factory.getPair(
                    _paths[tokenIns_[i]][j],
                    _paths[tokenIns_[i]][j + 1]
                );

                if (_pairCounters[pair] == 1) _pairs.remove(pair);
                _decrementCounter(pair);
            }
            delete _paths[tokenIns_[i]];
        }
    }

    function _incrementCounter(address pair_) internal {
        _pairCounters[pair_] = _pairCounters[pair_] + 1;
    }

    function _decrementCounter(address pair_) internal {
        if (_pairCounters[pair_] > 0) _pairCounters[pair_] = _pairCounters[pair_] - 1;
    }

    function _isPairExistAtUniswap(
        address token1_,
        address token2_
    ) internal view returns (bool, address) {
        address pair_ = uniswapV2Factory.getPair(token1_, token2_);
        if (pair_ == address(0)) return (false, pair_);
        return (true, pair_);
    }

    function _getPrice(address pair_, address expectedToken_) internal view returns (uint256) {
        PairInfo storage pairInfo = _pairInfos[pair_];

        if (pairInfo.blockTimestamps.length == 0) {
            return 0;
        }

        uint256 index_ = pairInfo.blockTimestamps.lowerBound(block.timestamp - timeWindow);
        index_ = index_ == 0 ? index_ : index_ - 1;

        uint256 price0CumulativeOld = pairInfo.prices0Cumulative[index_];
        uint256 price1CumulativeOld = pairInfo.prices1Cumulative[index_];
        uint256 blockTimestampOld = pairInfo.blockTimestamps[index_];

        uint256 price0_;
        uint256 price1_;

        unchecked {
            (uint256 price0Cumulative, uint256 price1Cumulative, uint256 blockTimestamp) = pair_
                .currentCumulativePrices();

            require(
                (blockTimestamp != blockTimestampOld),
                "Oracle: blockTimestamp doesn't change"
            );

            price0_ =
                (price0Cumulative - price0CumulativeOld) /
                (blockTimestamp - blockTimestampOld);
            price1_ =
                (price1Cumulative - price1CumulativeOld) /
                (blockTimestamp - blockTimestampOld);
        }

        return expectedToken_ == IUniswapV2Pair(pair_).token0() ? price0_ : price1_;
    }
}
