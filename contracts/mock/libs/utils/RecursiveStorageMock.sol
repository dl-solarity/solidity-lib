// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/utils/TypeCaster.sol";
import "../../../libs/utils/RecursiveStorageUtils.sol";

contract RecursiveStorageMock {
    using TypeCaster for *;
    using RecursiveStorageUtils for *;

    RecursiveStorageUtils.RecursiveStorage private _recursiveStorage;

    function setUint256(string memory key_, uint256 value_) external {
        _recursiveStorage.set(key_, value_.toBytes());
    }

    function setUint256(string[] memory key_, uint256 value_) external {
        _recursiveStorage.set(key_, value_.toBytes());
    }

    function removeUint256(string memory key_) external {
        _recursiveStorage.remove(key_);
    }

    function removeUint256(string[] memory key_) external {
        _recursiveStorage.remove(key_);
    }

    function getUint256(string memory key_) external view returns (uint256) {
        return _recursiveStorage.get(key_).asUint256();
    }

    function getUint256(string[] memory key_) external view returns (uint256) {
        return _recursiveStorage.get(key_).asUint256();
    }
}
