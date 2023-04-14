// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {StringSet} from "../../../libs/data-structures/StringSet.sol";
import {Paginator} from "../../../libs/arrays/Paginator.sol";

contract PaginatorMock {
    using Paginator for *;
    using EnumerableSet for *;
    using StringSet for StringSet.Set;
    using Strings for uint256;

    uint256[] internal _uintArr;
    address[] internal _addressArr;
    bytes32[] internal _bytesArr;
    EnumerableSet.UintSet internal _uintSet;
    EnumerableSet.AddressSet internal _addressSet;
    EnumerableSet.Bytes32Set internal _bytesSet;
    StringSet.Set internal _stringSet;

    function pushUint(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _uintArr.push(100 + i);
            _uintSet.add(100 + i);
        }
    }

    function pushAddress(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _addressArr.push(address(uint160(i)));
            _addressSet.add(address(uint160(i)));
        }
    }

    function pushBytes(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _bytesArr.push(bytes32(i));
            _bytesSet.add(bytes32(i));
        }
    }

    function pushString(uint256 length_) external {
        for (uint256 i = 0; i < length_; i++) {
            _stringSet.add(i.toString());
        }
    }

    function partUintArr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _uintArr.part(offset_, limit_);
    }

    function partUintSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _uintSet.part(offset_, limit_);
    }

    function partAddressArr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory) {
        return _addressArr.part(offset_, limit_);
    }

    function partAddressSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory) {
        return _addressSet.part(offset_, limit_);
    }

    function partBytesArr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        return _bytesArr.part(offset_, limit_);
    }

    function partBytesSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        return _bytesSet.part(offset_, limit_);
    }

    function partStringSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory) {
        return _stringSet.part(offset_, limit_);
    }
}
