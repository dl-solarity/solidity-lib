// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../libs/arrays/Paginator.sol";

contract PaginatorMock {
    using Paginator for *;
    using EnumerableSet for *;

    uint256[] public uintArr;
    address[] public addressArr;
    bytes32[] public bytesArr;
    EnumerableSet.UintSet uintSet;
    EnumerableSet.AddressSet addressSet;
    EnumerableSet.Bytes32Set bytesSet;

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

    function partUintArr(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        return uintArr.part(offset, limit);
    }

    function partUintSet(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        return uintSet.part(offset, limit);
    }

    function partAddressArr(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        return addressArr.part(offset, limit);
    }

    function partAddressSet(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        return addressSet.part(offset, limit);
    }

    function partBytesArr(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        return bytesArr.part(offset, limit);
    }

    function partBytesSet(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        return bytesSet.part(offset, limit);
    }
}
