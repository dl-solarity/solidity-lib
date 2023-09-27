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
 * @title OracleV2
 * @dev A contract for retrieving price feeds from Uniswap V2 pairs.
 */
abstract contract OracleV2 is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using UniswapV2OracleLibrary for address;
    using ArrayHelper for uint256[];
    using Math for uint256;

    struct PairInfo {
        uint256[] prices0Cumulative;
        uint256[] prices1Cumulative;
        uint256[] blockTimestamps;
        uint256 counter;
    }

    IUniswapV2Factory public uniswapV2Factory;

    uint256 public timeWindow;

    EnumerableSet.AddressSet internal _pairs;
    mapping(address => address[]) internal _paths;
    mapping(address => PairInfo) internal _pairInfos;

    function __OracleV2_init(
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
        uint256 pairsLength = _pairs.length();

        for (uint256 i = 0; i < pairsLength; i++) {
            address pair_ = _pairs.at(i);

            PairInfo storage pairInfo = _pairInfos[pair_];
            uint256[] storage pairTimestamps = pairInfo.blockTimestamps;

            (uint256 price0Cumulative_, uint256 price1Cumulative_, uint256 blockTimestamp_) = pair_
                .currentCumulativePrices();

            if (
                pairTimestamps.length == 0 ||
                blockTimestamp_ > pairTimestamps[pairTimestamps.length - 1]
            ) {
                pairInfo.prices0Cumulative.push(price0Cumulative_);
                pairInfo.prices1Cumulative.push(price1Cumulative_);
                pairInfo.blockTimestamps.push(blockTimestamp_);
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
        uint256 pathLength_ = path.length;

        require(pathLength_ > 0, "OracleV2: invalid path");

        address tokenOut_ = path[pathLength_ - 1];

        for (uint256 i = 0; i < pathLength_ - 1; i++) {
            address currentToken_ = path[i];
            address nextToken_ = path[i + 1];
            address pair_ = uniswapV2Factory.getPair(currentToken_, nextToken_);
            uint256 price_ = _getPrice(pair_, currentToken_);

            if (price_ == 0) {
                return (0, tokenOut_);
            }

            amount_ = price_.mulDiv(amount_, 2 ** 112);
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
        uint256 numberOfPaths_ = paths_.length;

        for (uint256 i = 0; i < numberOfPaths_; i++) {
            uint256 pathLength_ = paths_[i].length;

            require(pathLength_ >= 2, "OracleV2: path must be longer than 2");

            for (uint256 j = 0; j < paths_[i].length - 1; j++) {
                (bool isExist, address pair) = _isPairExistAtUniswap(
                    paths_[i][j],
                    paths_[i][j + 1]
                );
                require(isExist, "OracleV2: uniswap pair doesn't exist");
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
        uint256 numberOfPaths_ = tokenIns_.length;

        for (uint256 i = 0; i < numberOfPaths_; i++) {
            uint256 pathLength_ = _paths[tokenIns_[i]].length;

            for (uint256 j = 0; j < pathLength_ - 1; j++) {
                address pair = uniswapV2Factory.getPair(
                    _paths[tokenIns_[i]][j],
                    _paths[tokenIns_[i]][j + 1]
                );

                if (_pairInfos[pair].counter == 1) {
                    _pairs.remove(pair);
                }
                _decrementCounter(pair);
            }
            delete _paths[tokenIns_[i]];
        }
    }

    function _incrementCounter(address pair_) internal {
        _pairInfos[pair_].counter++;
    }

    function _decrementCounter(address pair_) internal {
        if (_pairInfos[pair_].counter > 0) {
            _pairInfos[pair_].counter--;
        }
    }

    function _isPairExistAtUniswap(
        address token1_,
        address token2_
    ) internal view returns (bool, address) {
        address pair_ = uniswapV2Factory.getPair(token1_, token2_);
        return (pair_ != address(0), pair_);
    }

    function _getPrice(address pair_, address expectedToken_) internal view returns (uint256) {
        PairInfo storage pairInfo = _pairInfos[pair_];

        if (pairInfo.blockTimestamps.length == 0) {
            return 0;
        }

        uint256 index_ = pairInfo.blockTimestamps.lowerBound(block.timestamp - timeWindow);
        index_ = index_ == 0 ? index_ : index_ - 1;

        uint256 price0CumulativeOld_ = pairInfo.prices0Cumulative[index_];
        uint256 price1CumulativeOld_ = pairInfo.prices1Cumulative[index_];
        uint256 blockTimestampOld_ = pairInfo.blockTimestamps[index_];

        uint256 price0_;
        uint256 price1_;

        unchecked {
            (uint256 price0Cumulative_, uint256 price1Cumulative_, uint256 blockTimestamp_) = pair_
                .currentCumulativePrices();

            if (blockTimestamp_ != blockTimestampOld_) {
                price0_ =
                    (price0Cumulative_ - price0CumulativeOld_) /
                    (blockTimestamp_ - blockTimestampOld_);
                price1_ =
                    (price1Cumulative_ - price1CumulativeOld_) /
                    (blockTimestamp_ - blockTimestampOld_);
            } else {
                price0_ = price0Cumulative_ / blockTimestamp_;
                price1_ = price1Cumulative_ / blockTimestamp_;
            }
        }

        return expectedToken_ == IUniswapV2Pair(pair_).token0() ? price0_ : price1_;
    }
}
