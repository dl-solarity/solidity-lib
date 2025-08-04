// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {BlockHeader, BlockHeaderData} from "../../../libs/bitcoin/BlockHeader.sol";

contract BlockHeaderMock {
    using BlockHeader for bytes;

    function parseBlockHeaderData(
        bytes calldata blockHeaderRaw_,
        bool returnInBEFormat_
    ) external pure returns (BlockHeaderData memory, bytes32) {
        return blockHeaderRaw_.parseBlockHeaderData(returnInBEFormat_);
    }

    function toRawBytes(BlockHeaderData memory headerData_) external pure returns (bytes memory) {
        return BlockHeader.toRawBytes(headerData_);
    }
}
