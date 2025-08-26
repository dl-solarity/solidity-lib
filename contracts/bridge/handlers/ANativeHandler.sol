// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title NativeHandler
 */
abstract contract ANativeHandler {
    receive() external payable {}

    function _depositNative() internal virtual {
        require(msg.value > 0, "NativeHandler: zero value");
    }

    function _withdrawNative(uint256 amount_, address receiver_) internal virtual {
        require(amount_ > 0, "NativeHandler: amount is zero");
        require(receiver_ != address(0), "NativeHandler: receiver is zero");

        (bool sent_, ) = payable(receiver_).call{value: amount_}("");

        require(sent_, "NativeHandler: can't send eth");
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
