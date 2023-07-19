// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/**
 * @notice The PoolContractsRegistry module
 *
 * The helper BeaconProxy that get deployed by the PoolFactory. Note that the external
 * `implementation()` function is added to the contract to provide compatability with the
 * Etherscan. This means that the implementation must not have such a function declared.
 */
contract PublicBeaconProxy is BeaconProxy {
    constructor(address beacon_, bytes memory data_) payable BeaconProxy(beacon_, data_) {}

    /**
     * @notice The function that returns implementation contract this proxy points to
     * @return address the implementation address
     */
    function implementation() external view virtual returns (address) {
        return _implementation();
    }
}
