// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EC256} from "../../../libs/crypto/EC256.sol";

contract EC256Mock {
    using EC256 for *;

    EC256.Curve public secp256k1CurveParams =
        EC256.Curve({
            a: 0x0000000000000000000000000000000000000000000000000000000000000000,
            b: 0x0000000000000000000000000000000000000000000000000000000000000007,
            gx: 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            gy: 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8,
            p: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f,
            n: 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
        });

    function affineInfinity() external view returns (EC256.APoint memory) {
        return secp256k1CurveParams.toAffine(EC256.jinfinity());
    }

    function basepoint() external view returns (EC256.APoint memory) {
        return secp256k1CurveParams.basepoint();
    }
}
