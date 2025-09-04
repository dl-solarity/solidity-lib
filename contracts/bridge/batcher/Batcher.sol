// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";

contract Batcher is IBatcher, ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Address for address;

    function execute(bytes calldata batch_) external payable nonReentrant {
        (address[] memory contracts_, uint256[] memory values_, bytes[] memory data_) = abi.decode(
            batch_,
            (address[], uint256[], bytes[])
        );

        for (uint256 i = 0; i < contracts_.length; ++i) {
            contracts_[i].functionCallWithValue(data_[i], values_[i]);
        }
    }

    receive() external payable {}
}
