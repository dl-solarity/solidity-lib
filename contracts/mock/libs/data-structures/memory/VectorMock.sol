// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Vector} from "../../../../libs/data-structures/memory/Vector.sol";
import {TypeCaster} from "../../../../libs/utils/TypeCaster.sol";

contract VectorMock {
    using Vector for *;
    using TypeCaster for *;

    function testNew() external pure {
        assembly {
            mstore(
                add(mload(0x40), 0x40),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
        }

        Vector.UintVector memory vector1_ = Vector.newUint();

        require(vector1_.length() == 0);

        assembly {
            mstore(
                add(mload(0x40), 0x60),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            mstore(
                add(mload(0x40), 0x80),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            mstore(
                add(mload(0x40), 0x100),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
        }

        Vector.UintVector memory vector2_ = Vector.newUint(3);

        require(vector2_.length() == 3);

        for (uint256 i = 0; i < vector2_.length(); i++) {
            require(vector2_.at(i) == 0);
        }
    }

    function testArrayPush() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        require(vector_._vector._allocation == 5);
        require(vector_.length() == 0);

        vector_.push([uint256(1), 2, 3].asDynamic());

        require(vector_.length() == 3);
    }

    function testPushAndPop() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        require(vector_._vector._allocation == 5);
        require(vector_.length() == 0);

        vector_.push(1);
        vector_.push(2);
        vector_.push(3);

        require(vector_.length() == 3);

        for (uint256 i = 0; i < vector_.length(); i++) {
            require(vector_.at(i) == i + 1);
        }

        vector_.pop();

        require(vector_.length() == 2);

        vector_.push(0);

        require(vector_.at(2) == 0);
    }

    function testResize() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        require(vector_._vector._allocation == 1);
        require(vector_.length() == 0);

        for (uint256 i = 0; i < 10; i++) {
            vector_.push(i);
        }

        require(vector_._vector._allocation == 16);
        require(vector_.length() == 10);

        uint256[] memory array_ = vector_.toArray();

        require(array_.length == 10);

        for (uint256 i = 0; i < array_.length; i++) {
            require(array_[i] == i);
        }
    }

    function testResizeAndSet() external pure {
        Vector.UintVector memory vector1_ = Vector.newUint(1);

        require(vector1_.length() == 1);
        require(vector1_.at(0) == 0);

        for (uint256 i = 1; i < 50; i++) {
            vector1_.push(i);
        }

        uint256[] memory array_ = vector1_.toArray();

        require(array_.length == 50);

        Vector.UintVector memory vector2_ = Vector.newUint(array_);

        require(vector2_.length() == 50);

        for (uint256 i = 0; i < 50; i++) {
            require(vector2_.at(i) == i);

            vector2_.set(i, 50 - i);

            require(vector2_.at(i) == 50 - i);
        }
    }

    function testEmptyPop() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.pop();
    }

    function testEmptySet() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.set(1, 0);
    }

    function testEmptyAt() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.at(0);
    }

    function testUintFunctionality() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        require(vector_.length() == 0);

        vector_.push(1);
        vector_.set(0, 2);
        vector_.push(2);
        vector_.set(vector_.length() - 1, 3);

        uint256[] memory array_ = vector_.toArray();

        require(array_.length == 2);
        require(array_[0] == 2);
        require(array_[1] == 3);

        array_[0] = 10;

        require(vector_.at(0) == 10);

        vector_ = Vector.newUint(5);
        array_ = vector_.toArray();

        require(array_.length == 5);

        vector_.push(0);
        vector_.pop();

        array_ = vector_.toArray();

        require(array_.length == 5);

        array_[array_.length - 1] = 1;
        vector_ = Vector.newUint(array_);

        require(vector_.length() == 5);
        require(vector_.at(vector_.length() - 1) == 1);

        vector_.push([uint256(1), 2, 3].asDynamic());

        require(vector_.length() == 8);
    }

    function testBytes32Functionality() external pure {
        Vector.Bytes32Vector memory vector_ = Vector.newBytes32();

        require(vector_.length() == 0);

        vector_.push(bytes32(uint256(1)));
        vector_.set(0, bytes32(uint256(2)));
        vector_.push(bytes32(uint256(2)));
        vector_.set(vector_.length() - 1, bytes32(uint256(3)));

        bytes32[] memory array_ = vector_.toArray();

        require(array_.length == 2);
        require(array_[0] == bytes32(uint256(2)));
        require(array_[1] == bytes32(uint256(3)));

        array_[0] = bytes32(uint256(10));

        require(vector_.at(0) == bytes32(uint256(10)));

        vector_ = Vector.newBytes32(5);
        array_ = vector_.toArray();

        require(array_.length == 5);

        vector_.push(0);
        vector_.pop();

        array_ = vector_.toArray();

        require(array_.length == 5);

        array_[array_.length - 1] = bytes32(uint256(1));
        vector_ = Vector.newBytes32(array_);

        require(vector_.length() == 5);
        require(vector_.at(vector_.length() - 1) == bytes32(uint256(1)));

        vector_.push([bytes32(uint256(5)), bytes32(uint256(4)), bytes32(uint256(3))].asDynamic());

        require(vector_.length() == 8);
    }

    function testAddressFunctionality() external pure {
        Vector.AddressVector memory vector_ = Vector.newAddress();

        require(vector_.length() == 0);

        vector_.push(address(1));
        vector_.set(0, address(2));
        vector_.push(address(2));
        vector_.set(vector_.length() - 1, address(3));

        address[] memory array_ = vector_.toArray();

        require(array_.length == 2);
        require(array_[0] == address(2));
        require(array_[1] == address(3));

        array_[0] = address(10);

        require(vector_.at(0) == address(10));

        vector_ = Vector.newAddress(5);
        array_ = vector_.toArray();

        require(array_.length == 5);

        vector_.push(address(0));
        vector_.pop();

        array_ = vector_.toArray();

        require(array_.length == 5);

        array_[array_.length - 1] = address(1);
        vector_ = Vector.newAddress(array_);

        require(vector_.length() == 5);
        require(vector_.at(vector_.length() - 1) == address(1));

        vector_.push([address(5), address(4), address(3)].asDynamic());

        require(vector_.length() == 8);
    }
}
