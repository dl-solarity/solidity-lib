// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice A simple library to convert static arrays into dynamic (uint256, address, bool, string, bytes32)
 */
library ArrayConverter {
    /**
     *  @notice The function to convert static array to dynamic
     *  @param static_ the static array to convert
     *  @return dynamic_ the converted dynamic array
     */
    function toDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[6] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[7] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[8] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[9] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        uint256[10] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyUint(pointerS, static_.length);
    }

    function toDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[6] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[7] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[8] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[9] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(
        address[10] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyAddress(pointerS, static_.length);
    }

    function toDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[6] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[7] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[8] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[9] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(bool[10] memory static_) internal pure returns (bool[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBool(pointerS, static_.length);
    }

    function toDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[6] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[7] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[8] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(string[9] memory static_) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(
        string[10] memory static_
    ) internal pure returns (string[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyString(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[6] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[7] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[8] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[9] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function toDynamic(
        bytes32[10] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        uint256 pointerS;

        assembly {
            pointerS := static_
        }

        return _copyBytes(pointerS, static_.length);
    }

    function _copyUint(
        uint256 pointerS_,
        uint256 length_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory dynamic_ = new uint256[](length_);
        uint256 pointerD_;

        assembly {
            pointerD_ := dynamic_
        }

        _copy(pointerD_, pointerS_, length_);
        return dynamic_;
    }

    function _copyAddress(
        uint256 pointerS_,
        uint256 length_
    ) internal pure returns (address[] memory) {
        address[] memory dynamic_ = new address[](length_);
        uint256 pointerD_;

        assembly {
            pointerD_ := dynamic_
        }

        _copy(pointerD_, pointerS_, length_);
        return dynamic_;
    }

    function _copyBool(uint256 pointerS_, uint256 length_) internal pure returns (bool[] memory) {
        bool[] memory dynamic_ = new bool[](length_);
        uint256 pointerD_;

        assembly {
            pointerD_ := dynamic_
        }

        _copy(pointerD_, pointerS_, length_);
        return dynamic_;
    }

    function _copyString(
        uint256 pointerS_,
        uint256 length_
    ) internal pure returns (string[] memory) {
        string[] memory dynamic_ = new string[](length_);
        uint256 pointerD_;

        assembly {
            pointerD_ := dynamic_
        }

        _copy(pointerD_, pointerS_, length_);
        return dynamic_;
    }

    function _copyBytes(
        uint256 pointerS_,
        uint256 length_
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory dynamic_ = new bytes32[](length_);
        uint256 pointerD_;

        assembly {
            pointerD_ := dynamic_
        }

        _copy(pointerD_, pointerS_, length_);
        return dynamic_;
    }

    function _copy(uint256 locationD_, uint256 locationS_, uint256 length_) internal pure {
        assembly {
            for {
                let i := 0
            } lt(i, length_) {
                i := add(i, 1)
            } {
                locationD_ := add(locationD_, 0x20)

                mstore(locationD_, mload(locationS_))

                locationS_ := add(locationS_, 0x20)
            }
        }
    }
}
