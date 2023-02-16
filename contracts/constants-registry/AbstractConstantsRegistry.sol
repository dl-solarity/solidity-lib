// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libs/utils/BytesCaster.sol";
import "../libs/utils/ConstantsRegistryUtils.sol";

abstract contract AbstractConstantsRegistry is Initializable {
    using ConstantsRegistryUtils for *;
    using BytesCaster for *;

    ConstantsRegistryUtils.ConstantsRegistryStorage private _constants;

    /**
     *  @notice The proxy initializer function
     */
    function __ConstantsRegistry_init() internal onlyInitializing {}

    function getUint256Constant(string[] memory key_) public view returns (uint256) {
        return _constants.get(key_).asUint256();
    }

    function _setUint256Constant(string[] memory key_, uint256 value_) internal {
        _constants.set(key_, value_.toBytes());
    }
}
