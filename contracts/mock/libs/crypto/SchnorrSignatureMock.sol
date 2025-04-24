// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SchnorrSignature} from "../../../libs/crypto/SchnorrSignature.sol";

contract SchnorrSignatureMock {
    function verifySignature(
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) external view returns (bool isVerified_) {
        return SchnorrSignature.verifySignature(hashedMessage_, signature_, pubKey_);
    }
}
