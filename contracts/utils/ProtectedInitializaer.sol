// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title ProtectedInitializer
 * @notice A utility contract that provides protected initialization capabilities for contracts
 * that depend on each other. This contract ensures that contracts are never left in an
 * unprotected state during deployment by allowing a second initialization phase that is
 * restricted to the deployer only.
 */
contract ProtectedInitializer is Initializable, Context {
    /// @notice The address of the contract deployer
    address private immutable DEPLOYER;

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
        DEPLOYER = deployer_;
    }

    /**
     * @dev Reverts if the caller is not the deployer
     */
    function _requireDeployer() internal view {
        if (!_isDeployer()) {
            revert OnlyDeployer(_msgSender());
        }
    }

    /**
     * @dev Internal function to check if the given address is the deployer
     */
    function _isDeployer() internal view returns (bool) {
        return DEPLOYER == _msgSender();
    }
}
