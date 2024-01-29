// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Vesting} from "../../finance/Vesting.sol";
import {ERC20Mock} from "../tokens/ERC20Mock.sol";

contract VestingMock is Vesting {
    constructor() {
        __VestingMock_init();
    }

    function __VestingMock_init() public initializer {
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

    function withdrawFromVesting(uint256 vestingId_) public {
        (uint256 _amountToPay, address _vestingToken) = _withdrawFromVesting(vestingId_);

        ERC20Mock(_vestingToken).transferFrom(address(this), msg.sender, _amountToPay);
    }
}
