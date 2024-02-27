// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Vesting} from "../../../finance/vesting/Vesting.sol";
import {ERC20Mock} from "../../tokens/ERC20Mock.sol";

contract VestingMock is Vesting {
    function __VestingMock_init() public initializer {
        __Vesting_init();
    }

    function vestingInit() public {
        __Vesting_init();
    }

    function createSchedule(Schedule memory _schedule) public {
        _createSchedule(_schedule);
    }

    function createBaseSchedule(BaseSchedule memory _schedule) public {
        _createSchedule(_schedule);
    }

    function createVesting(VestingData memory vestingData_) public returns (uint256 vestingId_) {
        vestingId_ = _createVesting(vestingData_);

        ERC20Mock(vestingData_.vestingToken).transferFrom(
            msg.sender,
            address(this),
            vestingData_.vestingAmount
        );
    }

    function vestingCalculation(
        uint256 scheduleId_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_
    ) public view returns (uint256 vestedAmount_) {
        return
            _vestingCalculation(
                scheduleId_,
                totalVestingAmount_,
                vestingStartTime_,
                timestampUpTo_
            );
    }
}
