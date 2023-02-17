// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/utils/TypeCaster.sol";
import "../../../libs/utils/RecursiveStorage.sol";

contract RecursiveStorageMock {
    using TypeCaster for *;
    using RecursiveStorage for *;

    RecursiveStorage.Storage private _recursiveStorage;

    function setBytes(string memory key_, bytes memory data_) external {
        _recursiveStorage.set(key_, data_);
    }

    function setCompositeKeyBytes(string[] memory key_, bytes memory data_) external {
        _recursiveStorage.set(key_, data_);
    }

    function setUint256(string memory key_, uint256 value_) external {
        _recursiveStorage.set(key_, value_.toBytes());
    }

    function setCompositeKeyUint256(string[] memory key_, uint256 value_) external {
        _recursiveStorage.set(key_, value_.toBytes());
    }

    function remove(string memory key_) external {
        _recursiveStorage.remove(key_);
    }

    function removeCompositeKey(string[] memory key_) external {
        _recursiveStorage.remove(key_);
    }

    function getUint256(string memory key_) external view returns (uint256) {
        return _recursiveStorage.get(key_).asUint256();
    }

    function getCompositeKeyUint256(string[] memory key_) external view returns (uint256) {
        return _recursiveStorage.get(key_).asUint256();
    }

    function getBytes(string memory key_) external view returns (bytes memory) {
        return _recursiveStorage.get(key_);
    }

    function getCompositeKeyBytes(string[] memory key_) external view returns (bytes memory) {
        return _recursiveStorage.get(key_);
    }

    function exists(string memory key_) external view returns (bool) {
        return _recursiveStorage.get(key_).length > 0;
    }

    function existsCompositeKey(string[] memory key_) external view returns (bool) {
        return _recursiveStorage.get(key_).length > 0;
    }
}
