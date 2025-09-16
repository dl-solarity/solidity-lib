// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";

/**
 * @notice The Batcher module
 *
 * IMPORTANT:
 * This contract is not meant to hold funds. Any remaining funds will eventually be swept after execution.
 */
contract Batcher is IBatcher, ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Address for *;

    struct ExecutionData {
        address target;
        uint256 value;
        bytes data;
    }

    /**
     * @inheritdoc IBatcher
     */
    function execute(bytes calldata batch_) external payable nonReentrant {
        ExecutionData[] memory calls_ = abi.decode(batch_, (ExecutionData[]));

        for (uint256 i = 0; i < calls_.length; ++i) {
            ExecutionData memory call_ = calls_[i];

            if (call_.data.length > 0) {
                call_.target.functionCallWithValue(call_.data, call_.value);
            } else {
                payable(call_.target).sendValue(call_.value);
            }
        }
    }

    receive() external payable {}
}
