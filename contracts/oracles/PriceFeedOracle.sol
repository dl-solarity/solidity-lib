// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UniswapV2OracleLibrary} from "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

import {ArrayHelper} from "../libs/arrays/ArrayHelper.sol";

/**
 * @title PriceFeedOracle
 * @dev A contract for retrieving price feeds from Uniswap V2 pairs.
 */
abstract contract PriceFeedOracle is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using UniswapV2OracleLibrary for address;
    using ArrayHelper for uint256[];
    using Math for uint256;

    struct PairInfo {
        uint256[] prices0Cumulative;
        uint256[] prices1Cumulative;
        uint256[] blockTimestamps;
    }

    IUniswapV2Factory public uniswapV2Factory; //was immutable, now mutable so it is possible to call in init func

    uint256 public timeWindow;

    EnumerableSet.AddressSet internal _pairs;
    mapping(address => address[]) internal _paths;
    mapping(address => PairInfo) internal _pairInfos;

    function __PriceFeedOracle_init(
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

    //why is usd here in naming. price in tokenOut
    //add tokenOut_ as param in future?
    /**
     * @dev Retrieves the USD price of a token based on the provided token and amount.
     * @param tokenIn_ The input token address.
     * @param amount_ The amount of the input token.
     * @return The USD price and the output token address.
     */
    function getPriceUSD(
        address tokenIn_,
        uint256 amount_
    ) external view returns (uint256, address) {
        address[] storage path = _paths[tokenIn_];
        require(path.length > 0, "PriceFeedOracle: INVALID_PATH");

        address tokenOut_ = path[path.length - 1];

        for (uint256 i = 0; i < path.length - 1; i++) {
            address currentToken = path[i];
            address nextToken = path[i + 1];

            address pair = uniswapV2Factory.getPair(currentToken, nextToken);

            if (pair == address(0)) {
                return (0, tokenOut_);
            }

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

    //in child contracts check if pair exist on Uniswap V2 may be added
    /**
     * @dev Adds multiple Uniswap V2 pairs to the oracle.
     * @param pairs_ The array of pair addresses to add.
     */
    function _addPairs(address[] calldata pairs_) internal {
        for (uint256 i = 0; i < pairs_.length; i++) {
            _pairs.add(pairs_[i]);
        }
    }

    /**
     * @dev Adds multiple token paths to the oracle.
     * @param paths_ The array of token paths to add.
     */
    function _addPaths(address[][] calldata paths_) internal {
        bool isPathValid_;
        for (uint256 i = 0; i < paths_.length; i++) {
            require(paths_[i].length >= 2, "PriceFeedOracle: path must be longer than 2");

            isPathValid_ = true;
            for (uint256 j = 0; j < paths_[i].length - 1; j++) {
                if (!_isPairExist(paths_[i][j], paths_[i][j + 1])) {
                    isPathValid_ = false;
                    break;
                }
            }
            if (isPathValid_) _paths[paths_[i][0]] = paths_[i];

            //now only one path is possible from one particaular token. Is it meant to be?
        }
        updatePrices();
    }

    //hard to check does it affect the path
    /**
     * @dev Removes multiple Uniswap V2 pairs from the oracle.
     * @param pairs_ The array of pair addresses to remove.
     */
    function _removePairs(address[] calldata pairs_) internal {
        for (uint256 i = 0; i < pairs_.length; i++) {
            _pairs.remove(pairs_[i]);
        }
    }

    /**
     * @dev Removes multiple token paths from the oracle.
     * @param tokenIns_ The array of token addresses to remove.
     */
    function _removePaths(address[] calldata tokenIns_) internal {
        for (uint256 i = 0; i < tokenIns_.length; i++) {
            delete _paths[tokenIns_[i]];
        }
    }

    function _isPairExist(address token1_, address token2_) internal view returns (bool) {
        address pair_ = uniswapV2Factory.getPair(token1_, token2_);

        //is it needed? maybe in child contracts
        if (pair_ == address(0)) return false;

        return _pairs.contains(pair_);
    }

    function _getPrice(address pair_, address expectedToken_) internal view returns (uint256) {
        PairInfo storage pairInfo = _pairInfos[pair_];

        if (pairInfo.blockTimestamps.length == 0) {
            return 0;
        }

        uint256 index = pairInfo.blockTimestamps.lowerBound(block.timestamp - timeWindow);
        index = index == 0 ? index : index - 1;

        uint256 price0CumulativeOld = pairInfo.prices0Cumulative[index];
        uint256 price1CumulativeOld = pairInfo.prices1Cumulative[index];
        uint256 blockTimestampOld = pairInfo.blockTimestamps[index];

        uint256 price0;
        uint256 price1;

        unchecked {
            (uint256 price0Cumulative, uint256 price1Cumulative, uint256 blockTimestamp) = pair_
                .currentCumulativePrices();

            price0 =
                (price0Cumulative - price0CumulativeOld) /
                (blockTimestamp - blockTimestampOld);
            price1 =
                (price1Cumulative - price1CumulativeOld) /
                (blockTimestamp - blockTimestampOld);
        }

        if (price0 == 0) {
            return 0;
        }

        return expectedToken_ == IUniswapV2Pair(pair_).token0() ? price0 : price1;
    }
}
