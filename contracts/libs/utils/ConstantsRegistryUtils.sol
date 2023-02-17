// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./TypeCaster.sol";

library ConstantsRegistryUtils {
    using TypeCaster for *;

    struct ConstantsRegistryStorage {
        bytes _value;
        mapping(string => ConstantsRegistryStorage) _values;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string memory key_,
        bytes memory value_
    ) internal {
        require(value_.length > 0, "ConstantsRegistryUtils: empty value");

        _dive(constants, key_.asArray())._value = value_;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string[] memory key_,
        bytes memory value_
    ) internal {
        require(value_.length > 0, "ConstantsRegistryUtils: empty value");

        _dive(constants, key_)._value = value_;
    }

    function remove(ConstantsRegistryStorage storage constants, string memory key_) internal {
        ConstantsRegistryStorage storage _constants = _dive(constants, key_.asArray());

        require(_constants._value.length > 0, "ConstantsRegistryUtils: constant does not exist");

        _constants._value = bytes("");
    }

    function remove(ConstantsRegistryStorage storage constants, string[] memory key_) internal {
        ConstantsRegistryStorage storage _constants = _dive(constants, key_);

        require(_constants._value.length > 0, "ConstantsRegistryUtils: constant does not exist");

        _constants._value = bytes("");
    }

    function get(
        ConstantsRegistryStorage storage constants,
        string memory key_
    ) internal view returns (bytes memory) {
        return _dive(constants, key_.asArray())._value;
    }

    function get(
        ConstantsRegistryStorage storage constants,
        string[] memory key_
    ) internal view returns (bytes memory) {
        return _dive(constants, key_)._value;
    }

    function _dive(
        ConstantsRegistryStorage storage constants,
        string[] memory key_
    ) private view returns (ConstantsRegistryStorage storage) {
        ConstantsRegistryStorage storage _constants = constants;

        for (uint256 i = 0; i < key_.length; i++) {
            _constants = _constants._values[key_[i]];
        }

        return _constants;
    }
}
