// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../libs/decimals/DecimalsConverter.sol";

contract DecimalsConverterMock {
    using DecimalsConverter for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destDecimals
    ) external pure returns (uint256) {
        return amount.convert(baseDecimals, destDecimals);
    }

    function to18(uint256 amount, uint256 baseDecimals) external pure returns (uint256) {
        return amount.to18(baseDecimals);
    }

    function from18(uint256 amount, uint256 destDecimals) external pure returns (uint256) {
        return amount.from18(destDecimals);
    }

    function round18(uint256 amount, uint256 decimals) external pure returns (uint256) {
        return amount.round18(decimals);
    }
}
