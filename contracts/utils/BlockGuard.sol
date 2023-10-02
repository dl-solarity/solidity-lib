// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The BlockGuard module
 *
 * This module facilitates the flash-loan protection. Users may be prohibited from calling certain
 * functions in the same block e.g. via the Multicall.
 */
abstract contract BlockGuard {
    mapping(string => mapping(address => uint256)) private _lockedInBlocks;

    modifier lockBlock(string memory resource_, address key_) {
        _lockBlock(resource_, key_);
        _;
    }

    modifier checkBlock(string memory resource_, address key_) {
        _checkBlock(resource_, key_);
        _;
    }

    modifier checkLockBlock(string memory resource_, address key_) {
        _checkBlock(resource_, key_);
        _lockBlock(resource_, key_);
        _;
    }

    /**
     * @notice The function to save the block when the resource key has been locked
     * @param resource_ the id of the resource
     * @param key_ the key of the resource
     */
    function _lockBlock(string memory resource_, address key_) internal {
        _lockedInBlocks[resource_][key_] = block.number;
    }

    /**
     * @notice The function to check if the resource key is called in the same block
     * @param resource_ the id of the resource
     * @param key_ the key of the resource
     */
    function _checkBlock(string memory resource_, address key_) internal view {
        require(_lockedInBlocks[resource_][key_] != block.number, "BlockGuard: locked");
    }

    /**
     * @notice The function to fetch the latest block when the resource key has been locked
     * @param resource_ the id of the resource
     * @param key_ the key of the resource
     * @return block_ the block when the resource key has been locked
     */
    function _getLatestLockBlock(
        string memory resource_,
        address key_
    ) internal view returns (uint256 block_) {
        return _lockedInBlocks[resource_][key_];
    }
}
