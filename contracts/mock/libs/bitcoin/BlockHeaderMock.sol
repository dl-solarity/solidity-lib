// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {BlockHeader} from "../../../libs/bitcoin/BlockHeader.sol";

contract BlockHeaderMock {
    using BlockHeader for bytes;

    function parseBlockHeader(
        bytes calldata blockHeaderRaw_,
        bool returnInBEFormat_
    ) external pure returns (BlockHeader.HeaderData memory, bytes32) {
        return blockHeaderRaw_.parseBlockHeader(returnInBEFormat_);
    }

    function toRawBytes(
        BlockHeader.HeaderData memory headerData_,
        bool inputInBEFormat_
    ) external pure returns (bytes memory) {
        return BlockHeader.toRawBytes(headerData_, inputInBEFormat_);
    }
}
