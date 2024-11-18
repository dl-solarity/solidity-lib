// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ECDSA384, U384} from "../../../libs/crypto/ECDSA384.sol";

contract ECDSA384Mock {
    using ECDSA384 for *;

    ECDSA384.Parameters private _curveParams =
        ECDSA384.Parameters({
            a: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc",
            b: hex"b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef",
            gx: hex"aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7",
            gy: hex"3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f",
            p: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff",
            n: hex"ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973",
            lowSmax: hex"7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb5666294b9"
        });

    function verifySECP384r1(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return _curveParams.verify(abi.encodePacked(sha256(message_)), signature_, pubKey_);
    }

    function verifySECP384r1CustomCurveParameters(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_,
        bytes calldata customA_,
        bytes calldata customB_
    ) external view returns (bool) {
        ECDSA384.Parameters memory curveParams_ = _curveParams;
        curveParams_.a = customA_;
        curveParams_.b = customB_;

        return curveParams_.verify(abi.encodePacked(sha256(message_)), signature_, pubKey_);
    }

    function verifySECP384r1WithoutHashing(
        bytes calldata hashedMessage_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return _curveParams.verify(abi.encodePacked(hashedMessage_), signature_, pubKey_);
    }

    function cmpMock() external pure returns (int256 cmp_) {
        uint256 a_;
        uint256 b_;

        assembly {
            a_ := mload(0x40)
            b_ := add(a_, 0x40)

            mstore(add(a_, 0x20), 0x1234)
            mstore(add(b_, 0x20), 0x5678)

            mstore(0x40, add(b_, 0x40))
        }

        return U384.cmp(a_, b_);
    }
}
