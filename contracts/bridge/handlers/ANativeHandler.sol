// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IBridge} from "../../interfaces/bridge/IBridge.sol";

/**
 * @title NativeHandler
 */
abstract contract ANativeHandler {
    using Address for address payable;

    receive() external payable {}

    function _depositNative() internal virtual {
        if (msg.value == 0) revert IBridge.InvalidValue();
    }

    function _withdrawNative(uint256 amount_, address receiver_) internal virtual {
        if (amount_ == 0) revert IBridge.InvalidAmount();
        if (receiver_ == address(0)) revert IBridge.InvalidReceiver();

        payable(receiver_).sendValue(amount_);
    }

    function getNativeSignHash(
        uint256 amount_,
        address receiver_,
        bytes32 txHash_,
        uint256 txNonce_,
        uint256 chainId_
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(amount_, receiver_, txHash_, txNonce_, chainId_));
    }
}
