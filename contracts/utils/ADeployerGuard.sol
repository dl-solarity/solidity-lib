// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title DeployerGuard
 * @notice A utility contract that provides protected initialization capabilities for other contracts.
 *
 * Generally speaking, the common "Initializer" approach is easily front-runnable and shouldn't be used on its own.
 *
 * This simple utility ensures that contracts are never left in an unprotected state during deployment by
 * integrating a second validation step restricted to the deployer only.
 *
 * ## Usage example:
 *
 * ```
 * contract ProtectedImpl is ADeployerGuard {
 *     constructor() ADeployerGuard(msg.sender) {}
 *
 *     function __ERC20_init(
 *         string memory name_,
 *         string memory symbol_,
 *     ) external initializer onlyDeployer {
 *         __ERC20_init(name_, symbol_);
 *     }
 * }
 * ```
 */
abstract contract ADeployerGuard {
    /// @notice The address of the contract deployer
    address private immutable _GUARD_DEPLOYER;

    /// @notice Error thrown when a non-deployer address attempts to call deployer-only functions
    /// @param caller The address that attempted to call the function
    error OnlyDeployer(address caller);

    /**
     * @dev Modifier that restricts function access to the deployer only
     * @notice This modifier should be used on the initialization functions
     * to ensure their non-frontrunability
     */
    modifier onlyDeployer() {
        _requireDeployer(msg.sender);
        _;
    }

    /**
     * @dev Constructor that sets the deployer address
     */
    constructor(address deployer_) {
        _GUARD_DEPLOYER = deployer_;
    }

    /**
     * @dev Reverts if the caller is not the deployer
     */
    function _requireDeployer(address account_) internal view {
        if (!_isDeployer(account_)) {
            revert OnlyDeployer(account_);
        }
    }

    /**
     * @dev Internal function to check if the given address is the deployer
     */
    function _isDeployer(address account_) internal view returns (bool) {
        return _deployer() == account_;
    }

    /**
     * @dev Internal function to get the deployer address
     */
    function _deployer() internal view virtual returns (address) {
        return _GUARD_DEPLOYER;
    }
}
