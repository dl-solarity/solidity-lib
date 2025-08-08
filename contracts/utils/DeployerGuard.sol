// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title DeployerGuard
 * @notice A utility contract that provides protected initialization capabilities for contracts
 * that depend on each other. This contract ensures that contracts are never left in an
 * unprotected state during deployment by allowing a second initialization phase that is
 * restricted to the deployer only.
 */
contract DeployerGuard {
    /// @notice The address of the contract deployer
    address private immutable __SOLARITY_GUARD_DEPLOYER;

    /// @notice Error thrown when a non-deployer address attempts to call deployer-only functions
    /// @param caller The address that attempted to call the function
    error OnlyDeployer(address caller);

    /**
     * @dev Modifier that restricts function access to the deployer only
     * @notice This modifier should be used on second initialization functions
     * to ensure only the original deployer can establish cross-contract references
     */
    modifier onlyDeployer() {
        _requireDeployer();
        _;
    }

    /**
     * @dev Constructor that sets the deployer address
     */
    constructor(address deployer_) {
        __SOLARITY_GUARD_DEPLOYER = deployer_;
    }

    /**
     * @dev Reverts if the caller is not the deployer
     */
    function _requireDeployer() internal view {
        if (!_isDeployer()) {
            revert OnlyDeployer(msg.sender);
        }
    }

    /**
     * @dev Internal function to check if the given address is the deployer
     */
    function _isDeployer() internal view returns (bool) {
        return _deployer() == msg.sender;
    }

    /**
     * @dev Internal function to get the deployer address
     */
    function _deployer() internal view virtual returns (address) {
        return __SOLARITY_GUARD_DEPLOYER;
    }
}
