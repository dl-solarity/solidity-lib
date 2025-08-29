// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUSDCCrosschain is IERC20 {
    function mint(address to_, uint256 amount_) external;

    function burn(uint256 amount_) external;
}
