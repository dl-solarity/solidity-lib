// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../arrays/ArrayHelper.sol";

library ConstantsRegistryUtils {
    using ArrayHelper for *;

    struct ConstantsRegistryStorage {
        bool _exists;
        bytes _value;
        mapping(string => ConstantsRegistryStorage) _values;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string memory key_,
        bytes memory value_
    ) internal {
        _dive(constants, key_.asArray())._value = value_;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string[2] memory key_,
        bytes memory value_
    ) internal {
        _dive(constants, key_.asArray())._value = value_;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string memory key_,
        string memory subKey_,
        bytes memory value_
    ) internal {
        _dive(constants, [key_, subKey_].asArray())._value = value_;
    }

    function set(
        ConstantsRegistryStorage storage constants,
        string[] memory key_,
        bytes memory value_
    ) internal {
        _dive(constants, key_)._value = value_;
    }

    function get(
        ConstantsRegistryStorage storage constants,
        string memory key_
    ) internal view returns (bytes memory) {
        return _dive(constants, key_.asArray())._value;
    }

    function get(
        ConstantsRegistryStorage storage constants,
        string[2] memory key_
    ) internal view returns (bytes memory) {
        return _dive(constants, key_.asArray())._value;
    }

    function get(
        ConstantsRegistryStorage storage constants,
        string memory key_,
        string memory subKey_
    ) internal view returns (bytes memory) {
        return _dive(constants, [key_, subKey_].asArray())._value;
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
