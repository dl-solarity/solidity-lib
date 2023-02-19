// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TypeCaster {
    /**
     *  @notice The function that casts the list of `X` types to the list of `Y` types
     *  @param from the list of `X` types
     *  @return array_ the list of `Y` types
     */
    function asUint256Array(
        bytes32[] memory from
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asUint256Array(
        address[] memory from
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asAddressArray(
        bytes32[] memory from
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asAddressArray(
        uint256[] memory from
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asBytes32Array(
        uint256[] memory from
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from
        }
    }

    function asBytes32Array(
        address[] memory from
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from
        }
    }

    /**
     *  @notice The function to transform an element into an array
     *  @param from the element
     *  @return array_ the element as an array
     */
    function asSingletonArray(uint256 from) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from;
    }

    function asSingletonArray(address from) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from;
    }

    function asSingletonArray(string memory from) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from;
    }

    function asSingletonArray(bytes32 from) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from;
    }
}
