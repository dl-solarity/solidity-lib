// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The BlockGuard module
 *
 * This module facilitates the flash-loan protection mechanism. Users may be prohibited from calling certain
 * functions in the same block e.g. via the Multicall.
 *
 * ## Usage example:
 *
 * ```
 * contract NotFlashloanable is BlockGuard {
 *     function deposit(uint256 amount) external lockBlock("DEPOSIT", msg.sender) {
 *         . . .
 *     }
 *
 *     function withdraw(uint256 amount) external checkBlock("DEPOSIT", msg.sender) {
 *         . . .
 *     }
 * }
 * ```
 */
abstract contract ABlockGuard {
    struct ABlockGuardStorage {
        mapping(string resource => mapping(address key => uint256 block)) lockedInBlocks;
    }

    // bytes32(uint256(keccak256("solarity.contract.ABlockGuard")) - 1)
    bytes32 private constant A_BLOCK_GUARD_STORAGE =
        0x06ea6e036a07a5850b5065c6817e5fe3c9f293357867b6a3fbe568a6a46097e6;

    error BlockGuardLocked(string resource, address key);

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
     * @param resource_ the id of the resource (the shared function)
     * @param key_ the key of the resource (the caller)
     */
    function _lockBlock(string memory resource_, address key_) internal {
        ABlockGuardStorage storage $ = _getABlockGuardStorage();

        $.lockedInBlocks[resource_][key_] = _getBlockNumber();
    }

    /**
     * @notice The function to check if the resource key is called in the same block
     * @param resource_ the id of the resource (the shared function)
     * @param key_ the key of the resource (the caller)
     */
    function _checkBlock(string memory resource_, address key_) internal view {
        ABlockGuardStorage storage $ = _getABlockGuardStorage();

        if ($.lockedInBlocks[resource_][key_] == _getBlockNumber())
            revert BlockGuardLocked(resource_, key_);
    }

    /**
     * @notice The function to fetch the latest block when the resource key has been locked
     * @param resource_ the id of the resource (the shared function)
     * @param key_ the key of the resource (the caller)
     * @return block_ the block when the resource key has been locked
     */
    function _getLatestLockBlock(
        string memory resource_,
        address key_
    ) internal view returns (uint256 block_) {
        ABlockGuardStorage storage $ = _getABlockGuardStorage();

        return $.lockedInBlocks[resource_][key_];
    }

    /**
     * @notice The function to fetch the actual block number
     * @dev In L2 chains, `block.number` may be synced with the L1 block number, potentially causing delays.
     * If custom sources are required, override this function
     * @return block_ the actual block number
     */
    function _getBlockNumber() internal view virtual returns (uint256 block_) {
        return block.number;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getABlockGuardStorage() private pure returns (ABlockGuardStorage storage $) {
        assembly {
            $.slot := A_BLOCK_GUARD_STORAGE
        }
    }
}
