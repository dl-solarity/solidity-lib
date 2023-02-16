// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AbstractConstantsRegistry is Initializable {
    /**
     *  @notice The proxy initializer function
     */
    function __ConstantsRegistry_init() internal onlyInitializing {}
}
