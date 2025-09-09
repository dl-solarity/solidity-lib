// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice [ERC-7802](https://eips.ethereum.org/EIPS/eip-7802) crosschain token.
 */
interface IERC20Crosschain is IERC20 {
    function crosschainMint(address to_, uint256 amount_) external;

    function crosschainBurn(address from_, uint256 amount_) external;
}
