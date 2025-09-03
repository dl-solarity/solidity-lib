// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {IERC20Crosschain} from "../../../interfaces/bridge/tokens/IERC20Crosschain.sol";

import {ERC20Mock} from "../../tokens/ERC20Mock.sol";

contract ERC20CrosschainMock is IERC20Crosschain, ERC20Mock {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimalPlaces_
    ) ERC20Mock(name_, symbol_, decimalPlaces_) {}

    function crosschainMint(address to_, uint256 amount_) public {
        mint(to_, amount_);
    }

    function crosschainBurn(address from_, uint256 amount_) public {
        burn(from_, amount_);
    }
}
