// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Multicall.sol";

import "../../utils/BlockGuard.sol";

contract BlockGuardMock is Multicall, BlockGuard {
    string public constant DEPOSIT_WITHDRAW_RESOURCE = "DEPOSIT_WITHDRAW";
    string public constant LOCK_LOCK_RESOURCE = "LOCK_LOCK";

    function deposit() external lockBlock(DEPOSIT_WITHDRAW_RESOURCE, msg.sender) {}

    function withdraw() external checkBlock(DEPOSIT_WITHDRAW_RESOURCE, msg.sender) {}

    function lock() external checkLockBlock(LOCK_LOCK_RESOURCE, msg.sender) {}

    function getLatestLockBlock(
        string memory resource_,
        address key_
    ) external view returns (uint256) {
        return _getLatestLockBlock(resource_, key_);
    }
}
