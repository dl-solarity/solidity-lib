// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

import "../introspection/DiamondERC165.sol";

contract DiamondInit is DiamondERC165 {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        registerInterface(type(IERC165).interfaceId);

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
