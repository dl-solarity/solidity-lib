// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This library is used to convert numbers that use token's N decimals to M decimals.
 * Comes extremely handy with standardizing the business logic that is intended to work with many different ERC20 tokens
 * that have different precision (decimals). One can perform calculations with 18 decimals only and resort to convertion
 * only when the payouts (or interactions) with the actual tokes have to be made.
 *
 * The best usage scenario involves accepting and calculating values with 18 decimals throughout the project, despite the tokens decimals.
 *
 * Also it is recommended to call `round18()` function on the first execution line in order to get rid of the
 * trailing numbers if the destination decimals are less than 18
 *
 * ## Usage example:
 *
 * ```
 * contract Taker {
 *     ERC20 public USDC;
 *     uint256 public paid;
 *
 *     . . .
 *
 *     function pay(uint256 amount) external {
 *         uint256 decimals = USDC.decimals();
 *         amount = amount.round18(decimals);
 *
 *         paid += amount;
 *         USDC.transferFrom(msg.sender, address(this), amount.from18(decimals));
 *     }
 * }
 * ```
 */
library DecimalsConverter {
    /**
     * @notice The function to get the decimals of ERC20 token. Needed for bytecode optimization
     * @param token_ the ERC20 token
     * @return the decimals of provided token
     */
    function decimals(address token_) internal view returns (uint8) {
        return ERC20(token_).decimals();
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision
     * @param amount_ the number to convert
     * @param token_ the token, whose decimals will be precised to 18
     * @return the number brought to 18 decimals of precision
     */
    function to18(uint256 amount_, address token_) internal view returns (uint256) {
        return to18(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision
     * @param amount_ the number to convert
     * @param baseDecimals_ the current precision of the number
     * @return the number brought to 18 decimals of precision
     */
    function to18(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return convert(amount_, baseDecimals_, 18);
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision. Reverts if output is zero
     * @param amount_ the number to convert
     * @param token_ the token, whose decimals will be precised to 18
     * @return the number brought to 18 decimals of precision
     */
    function to18Safe(uint256 amount_, address token_) internal view returns (uint256) {
        return to18Safe(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision. Reverts if output is zero
     * @param amount_ the number to convert
     * @param baseDecimals_ the current precision of the number
     * @return the number brought to 18 decimals of precision
     */
    function to18Safe(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return convertSafe(amount_, baseDecimals_, precisionTo18);
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision
     * @param amount_ the number to covert
     * @param token_ the token, whose decimals will be used as desired decimals of precision
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18(uint256 amount_, address token_) internal view returns (uint256) {
        return from18(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision
     * @param amount_ the number to covert
     * @param destDecimals_ the desired precision decimals
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return convert(amount_, 18, destDecimals_);
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision.
     * Reverts if output is zero
     * @param amount_ the number to covert
     * @param token_ the token, whose decimals will be used as desired decimals of precision
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18Safe(uint256 amount_, address token_) internal view returns (uint256) {
        return from18Safe(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision.
     * Reverts if output is zero
     * @param amount_ the number to covert
     * @param destDecimals_ the desired precision decimals
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18Safe(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return convertSafe(amount_, destDecimals_, precisionFrom18);
    }

    /**
     * @notice The function to substitute the trailing digits of a number with zeros
     * @param amount_ the number to round. Should be with 18 precision decimals
     * @param decimals_ the required number precision
     * @return the rounded number. Comes with 18 precision decimals
     */
    function round18(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return to18(from18(amount_, decimals_), decimals_);
    }

    /**
     * @notice The function to substitute the trailing digits of a number with zeros. Reverts if output is zero
     * @param amount_ the number to round. Should be with 18 precision decimals
     * @param decimals_ the required number precision
     * @return the rounded number. Comes with 18 precision decimals
     */
    function round18Safe(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return convertSafe(amount_, decimals_, round18);
    }

    /**
     * @notice The function to do the token precision convertion
     * @param amount_ the amount to convert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @return the converted number
     */
    function roundTokens(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) internal view returns (uint256) {
        return convert(amount_, uint256(decimals(baseToken_)), uint256(decimals(destToken_)));
    }

    /**
     * @notice The function to do the token precision convertion. Reverts if output is zero
     * @param amount_ the amount to convert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @return the converted number
     */
    function roundTokensSave(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) internal view returns (uint256) {
        return convertTokensSafe(amount_, baseToken_, destToken_, roundTokens);
    }

    function precisionTo18(uint256 amount_, uint256 baseDecimals_) private pure returns (uint256) {
        return convert(amount_, baseDecimals_, 18);
    }

    function precisionFrom18(
        uint256 amount_,
        uint256 destDecimals_
    ) private pure returns (uint256) {
        return convert(amount_, 18, destDecimals_);
    }

    /**
     * @notice The function to do the precision convertion
     * @param amount_ the amount to covert
     * @param baseDecimals_ current number precision
     * @param destDecimals_ desired number precision
     * @return the converted number
     */
    function convert(
        uint256 amount_,
        uint256 baseDecimals_,
        uint256 destDecimals_
    ) private pure returns (uint256) {
        if (baseDecimals_ > destDecimals_) {
            amount_ = amount_ / 10 ** (baseDecimals_ - destDecimals_);
        } else if (baseDecimals_ < destDecimals_) {
            amount_ = amount_ * 10 ** (destDecimals_ - baseDecimals_);
        }

        return amount_;
    }

    /**
     * @notice The function wrapper to do the safe precision convertion. Reverts if output is zero
     * @param amount_ the amount to covert
     * @param decimals_ the precision decimals
     * @param _convertFunc the internal function pointer to "from", "to", or "round" functions
     * @return conversionResult_ the convertion result
     */
    function convertSafe(
        uint256 amount_,
        uint256 decimals_,
        function(uint256, uint256) internal pure returns (uint256) _convertFunc
    ) private pure returns (uint256 conversionResult_) {
        conversionResult_ = _convertFunc(amount_, decimals_);

        require(conversionResult_ > 0, "DecimalsConverter: conversion failed");
    }

    /**
     * @notice The function wrapper to do the safe precision convertion for ERC20 tokens. Reverts if output is zero
     * @param amount_ the amount to covert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @param _convertFunc the internal function pointer to "from", "to", or "round" functions
     * @return conversionResult_ the convertion result
     */
    function convertTokensSafe(
        uint256 amount_,
        address baseToken_,
        address destToken_,
        function(uint256, address, address) internal view returns (uint256) _convertFunc
    ) private view returns (uint256 conversionResult_) {
        conversionResult_ = _convertFunc(amount_, baseToken_, destToken_);

        require(conversionResult_ > 0, "DecimalsConverter: conversion failed");
    }
}
