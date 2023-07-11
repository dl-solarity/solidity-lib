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
        dynamic_ = new uint256[](1);
        dynamic_[0] = static_[0];
    }

    function toDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        for (uint256 i = 0; i < 2; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        for (uint256 i = 0; i < 3; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        for (uint256 i = 0; i < 4; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[6] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](6);

        for (uint256 i = 0; i < 6; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[7] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](7);

        for (uint256 i = 0; i < 7; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[8] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](8);

        for (uint256 i = 0; i < 8; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[9] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](9);

        for (uint256 i = 0; i < 9; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        uint256[10] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](1);
        dynamic_[0] = static_[0];
    }

    function toDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        for (uint256 i = 0; i < 2; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        for (uint256 i = 0; i < 3; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        for (uint256 i = 0; i < 4; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        for (uint256 i = 0; i < 5; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[6] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](6);

        for (uint256 i = 0; i < 6; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[7] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](7);

        for (uint256 i = 0; i < 7; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[8] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](8);

        for (uint256 i = 0; i < 8; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[9] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](9);

        for (uint256 i = 0; i < 9; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        address[10] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](10);

        for (uint256 i = 0; i < 10; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](1);
        dynamic_[0] = static_[0];
    }

    function toDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        for (uint256 i = 0; i < 2; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        for (uint256 i = 0; i < 3; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        for (uint256 i = 0; i < 4; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        for (uint256 i = 0; i < 5; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[6] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](6);

        for (uint256 i = 0; i < 6; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[7] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](7);

        for (uint256 i = 0; i < 7; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[8] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](8);

        for (uint256 i = 0; i < 8; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[9] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](9);

        for (uint256 i = 0; i < 9; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(bool[10] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](10);

        for (uint256 i = 0; i < 10; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](1);
        dynamic_[0] = static_[0];
    }

    function toDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        for (uint256 i = 0; i < 2; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        for (uint256 i = 0; i < 3; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        for (uint256 i = 0; i < 4; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[6] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](6);

        for (uint256 i = 0; i < 6; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[7] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](7);

        for (uint256 i = 0; i < 7; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[8] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](8);

        for (uint256 i = 0; i < 8; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(string[9] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](9);

        for (uint256 i = 0; i < 9; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        string[10] memory static_
    ) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](10);

        for (uint256 i = 0; i < 10; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](1);
        dynamic_[0] = static_[0];
    }

    function toDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        for (uint256 i = 0; i < 2; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        for (uint256 i = 0; i < 3; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        for (uint256 i = 0; i < 4; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        for (uint256 i = 0; i < 5; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[6] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](6);

        for (uint256 i = 0; i < 6; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[7] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](7);

        for (uint256 i = 0; i < 7; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[8] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](8);

        for (uint256 i = 0; i < 8; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[9] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](9);

        for (uint256 i = 0; i < 9; i++) {
            dynamic_[i] = static_[i];
        }
    }

    function toDynamic(
        bytes32[10] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](10);

        for (uint256 i = 0; i < 10; i++) {
            dynamic_[i] = static_[i];
        }
    }
}
