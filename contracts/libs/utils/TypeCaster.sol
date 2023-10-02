// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice This library simplifies non-obvious type castings
 */
library TypeCaster {
    /**
     * @notice The function that casts the list of `X`-type elements to the list of uint256
     * @param from_ the list of `X`-type elements
     * @return array_ the list of uint256
     */
    function asUint256Array(
        bytes32[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asUint256Array(
        address[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the list of `X`-type elements to the list of addresses
     * @param from_ the list of `X`-type elements
     * @return array_ the list of addresses
     */
    function asAddressArray(
        bytes32[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asAddressArray(
        uint256[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the list of `X`-type elements to the list of bytes32
     * @param from_ the list of `X`-type elements
     * @return array_ the list of bytes32
     */
    function asBytes32Array(
        uint256[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asBytes32Array(
        address[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function to transform an element into an array
     * @param from_ the element
     * @return array_ the element as an array
     */
    function asSingletonArray(uint256 from_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from_;
    }

    function asSingletonArray(address from_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from_;
    }

    function asSingletonArray(bool from_) internal pure returns (bool[] memory array_) {
        array_ = new bool[](1);
        array_[0] = from_;
    }

    function asSingletonArray(string memory from_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from_;
    }

    function asSingletonArray(bytes32 from_) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to convert static array to dynamic
     * @param static_ the static array to convert
     * @return dynamic_ the converted dynamic array
     */
    function asDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function _copy(uint256 locationS_, uint256 locationD_, uint256 length_) private pure {
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
