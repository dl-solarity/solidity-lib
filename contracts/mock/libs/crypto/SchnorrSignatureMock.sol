// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SchnorrSignature} from "../../../libs/crypto/SchnorrSignature.sol";

contract SchnorrSignatureMock {
    SchnorrSignature.Parameters private _secp256k1CurveParams =
        SchnorrSignature.Parameters({
            a: 0x0000000000000000000000000000000000000000000000000000000000000000,
            b: 0x0000000000000000000000000000000000000000000000000000000000000007,
            gx: 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            gy: 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8,
            p: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f,
            n: 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
        });

    function verifySECP256k1(
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) external view returns (bool isVerified_) {
        return SchnorrSignature.verify(_secp256k1CurveParams, hashedMessage_, signature_, pubKey_);
    }
}
