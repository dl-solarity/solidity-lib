// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {DepInitializer} from "../../utils/DepInitializer.sol";

contract ERC20UpgradeableMock is DepInitializer, ERC20Upgradeable {
    uint8 internal _decimals;

    constructor() DepInitializer(msg.sender) {}

    function __ERC20UpgradeableMock_init(
        string memory name_,
        string memory symbol_,
        uint8 decimalPlaces_
    ) external reinitializer(1) onlyDeployer {
        __ERC20_init(name_, symbol_);

        _decimals = decimalPlaces_;
    }

    function mint(address to_, uint256 amount_) public {
        _mint(to_, amount_);
    }

    function burn(address to_, uint256 amount_) public {
        _burn(to_, amount_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
