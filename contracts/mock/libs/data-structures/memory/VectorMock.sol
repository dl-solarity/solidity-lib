// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../../libs/data-structures/memory/Vector.sol";

import "hardhat/console.sol";

contract VectorMock {
    using Vector for Vector.Vector;

    function testPushAndPop() external pure {
        Vector.Vector memory vector_ = Vector.init();

        require(vector_._allocation == 5);
        require(vector_.length() == 0);

        vector_.push(bytes32(uint256(1)));
        vector_.push(bytes32(uint256(2)));
        vector_.push(bytes32(uint256(3)));

        require(vector_.length() == 3);

        for (uint256 i = 0; i < vector_.length(); i++) {
            require(vector_.at(i) == bytes32(i + 1));
        }

        vector_.pop();

        require(vector_.length() == 2);

        vector_.push(bytes32(0));

        require(vector_.at(2) == bytes32(0));
    }

    function testResize() external pure {
        Vector.Vector memory vector_ = Vector.init(0);

        require(vector_._allocation == 1);
        require(vector_.length() == 0);

        for (uint256 i = 0; i < 10; i++) {
            vector_.push(bytes32(i));
        }

        require(vector_.length() == 10);

        bytes32[] memory array_ = vector_.toArray();

        require(array_.length == 10);

        for (uint256 i = 0; i < array_.length; i++) {
            require(array_[i] == bytes32(i));
        }
    }

    function testResizeAndSet() external pure {
        Vector.Vector memory vector1_ = Vector.init(1);

        require(vector1_.length() == 1);
        require(vector1_.at(0) == bytes32(0));

        for (uint256 i = 1; i < 50; i++) {
            vector1_.push(bytes32(i));
        }

        bytes32[] memory array_ = vector1_.toArray();

        require(array_.length == 50);

        Vector.Vector memory vector2_ = Vector.init(array_);

        require(vector2_.length() == 50);

        for (uint256 i = 0; i < 50; i++) {
            require(vector2_.at(i) == bytes32(i));

            vector2_.set(i, bytes32(50 - i));

            require(vector2_.at(i) == bytes32(50 - i));
        }
    }

    function testEmptyPop() external pure {
        Vector.Vector memory vector_ = Vector.init(0);

        vector_.pop();
    }

    function testEmptySet() external pure {
        Vector.Vector memory vector_ = Vector.init(0);

        vector_.set(1, bytes32(0));
    }

    function testEmptyAt() external pure {
        Vector.Vector memory vector_ = Vector.init(0);

        vector_.at(0);
    }
}
