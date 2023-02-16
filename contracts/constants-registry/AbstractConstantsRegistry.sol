// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libs/utils/ConstantsRegistryUtils.sol";

abstract contract AbstractConstantsRegistry is Initializable {
    using ConstantsRegistryUtils for *;

    ConstantsRegistryUtils.ConstantsRegistryStorage private _constants;

    /**
     *  @notice The proxy initializer function
     */
    function __ConstantsRegistry_init() internal onlyInitializing {}
}
