// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {AbstractValueDistributor} from "../../staking/AbstractValueDistributor.sol";
import {DECIMAL} from "../../utils/Globals.sol";

contract AbstractValueDistributorMock is AbstractValueDistributor, Multicall {
    event SharesAdded(address user_, uint256 amount_);
    event SharesRemoved(address user_, uint256 amount_);
    event ValueDistributed(address user_, uint256 amount_);

    function addShares(address user_, uint256 amount_) external {
        _addShares(user_, amount_);
    }

    function removeShares(address user_, uint256 amount_) external {
        _removeShares(user_, amount_);
    }

    function distributeValue(address user_, uint256 amount_) external {
        _distributeValue(user_, amount_);
    }

    function userShares(address user_) external view returns (uint256) {
        return userDistribution(user_).shares;
    }

    function userOwedValue(address user_) external view returns (uint256) {
        return userDistribution(user_).owedValue;
    }

    function _afterAddShares(address user_, uint256 amount_) internal override {
        emit SharesAdded(user_, amount_);
    }

    function _afterRemoveShares(address user_, uint256 amount_) internal override {
        emit SharesRemoved(user_, amount_);
    }

    function _afterDistributeValue(address user_, uint256 amount_) internal override {
        emit ValueDistributed(user_, amount_);
    }
}
