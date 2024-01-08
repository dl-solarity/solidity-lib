// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ValueDistributor} from "./ValueDistributor.sol";

contract Staking is ValueDistributor {
    address public tokenToDistribute;
    uint256 public rate;

    function stake(uint256 amount_) public {
        _addShares(msg.sender, amount_);
    }

    function withdraw(uint256 amount_) public {
        _removeShares(msg.sender, amount_);
    }

    function _changeDistributionToken(address newToken_) internal {
        tokenToDistribute = newToken_;
    }

    function _setRate(uint256 newRate_) internal {
        _update(address(0));

        rate = newRate_;
    }

    function _afterAddShares(address user_, uint256 amount_) internal virtual override {
        IERC20(tokenToDistribute).transferFrom(user_, address(this), amount_); // FIXME USDT, decimals
    }

    function _afterRemoveShares(address user_, uint256 amount_) internal virtual override {
        IERC20(tokenToDistribute).transfer(user_, amount_); // FIXME USDT, decimals
    }

    function _getValueToDistribute(
        uint256 timeUpTo,
        uint256 timeLastUpdate
    ) internal view virtual override returns (uint256) {
        return rate * (timeUpTo - timeLastUpdate);
    }
}
