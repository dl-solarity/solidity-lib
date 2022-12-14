// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../libs/arrays/Paginator.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PaginatorMock {
    using Paginator for uint256[];
    using Paginator for address[];
    using Paginator for bytes32[];
    using Paginator for EnumerableSet.UintSet;
    using Paginator for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.Bytes32Set;
    using Paginator for StringSet.Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using StringSet for StringSet.Set;
    using Strings for uint256;

    uint256[] public uintArr;
    address[] public addressArr;
    bytes32[] public bytesArr;
    EnumerableSet.UintSet uintSet;
    EnumerableSet.AddressSet addressSet;
    EnumerableSet.Bytes32Set bytesSet;
    StringSet.Set stringSet;

    function pushUint(uint256 length) external {
        for (uint256 i; i < length; i++) {
            uintArr.push(100 + i);
            uintSet.add(100 + i);
        }
    }

    function pushAddress(uint256 length) external {
        for (uint256 i; i < length; i++) {
            addressArr.push(address(uint160(i)));
            addressSet.add(address(uint160(i)));
        }
    }

    function pushBytes(uint256 length) external {
        for (uint256 i; i < length; i++) {
            bytesArr.push(bytes32(i));
            bytesSet.add(bytes32(i));
        }
    }

    function pushString(uint256 length) external {
        for (uint256 i = 0; i < length; i++) {
            stringSet.add(i.toString());
        }
    }

    function partUintArr(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        return uintArr.part(offset, limit);
    }

    function partUintSet(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        return uintSet.part(offset, limit);
    }

    function partAddressArr(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory) {
        return addressArr.part(offset, limit);
    }

    function partAddressSet(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory) {
        return addressSet.part(offset, limit);
    }

    function partBytesArr(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        return bytesArr.part(offset, limit);
    }

    function partBytesSet(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        return bytesSet.part(offset, limit);
    }

    function partStringSet(uint256 offset, uint256 limit) external view returns (string[] memory) {
        return stringSet.part(offset, limit);
    }
}
