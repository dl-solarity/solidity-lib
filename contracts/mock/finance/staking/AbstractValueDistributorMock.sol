// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {AbstractValueDistributor} from "../../../finance/staking/AbstractValueDistributor.sol";
import {DECIMAL} from "../../../utils/Globals.sol";

contract AbstractValueDistributorMock is AbstractValueDistributor, Multicall {
    function addShares(address user_, uint256 amount_) external {
        _addShares(user_, amount_);
    }

    function removeShares(address user_, uint256 amount_) external {
        _removeShares(user_, amount_);
    }

    function distributeValue(address user_, uint256 amount_) external {
        _distributeValue(user_, amount_);
    }

    function distributeAllValue(address user_) external {
        _distributeAllValue(user_);
    }

    function userShares(address user_) external view returns (uint256) {
        return userDistribution(user_).shares;
    }

    function userOwedValue(address user_) external view returns (uint256) {
        return userDistribution(user_).owedValue;
    }

    function _getValueToDistribute(
        uint256 timeUpTo_,
        uint256 timeLastUpdate_
    ) internal view virtual override returns (uint256) {
        return DECIMAL * (timeUpTo_ - timeLastUpdate_);
    }
}
